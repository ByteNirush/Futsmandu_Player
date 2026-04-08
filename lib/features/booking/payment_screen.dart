import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/esewa_payment_config.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import 'data/services/player_payments_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final PlayerPaymentsService _paymentsService = PlayerPaymentsService.instance;
  final AppLinks _appLinks = AppLinks();

  String? _gateway;
  int _seconds = 420;
  bool _loading = false;
  Timer? _timer;
  bool _timerInitialized = false;
  StreamSubscription<Uri>? _khaltiLinkSubscription;

  String? _pendingKhaltiPidx;
  String? _pendingKhaltiBookingId;
  Map<String, dynamic>? _pendingKhaltiArgs;
  bool _isAwaitingKhaltiCallback = false;
  bool _isVerifyingKhaltiCallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForKhaltiCallbackLinks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timerInitialized) return;
    _timerInitialized = true;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final heldBooking = args?['heldBooking'] is Map
        ? (args?['heldBooking'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    _seconds = _secondsUntilExpiry(heldBooking['hold_expires_at']);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
          Navigator.pushReplacementNamed(context, '/hold-expired');
        }
      });
    });
  }

  int _secondsUntilExpiry(dynamic rawExpiry) {
    if (rawExpiry is! String || rawExpiry.isEmpty) return 420;
    final parsed = DateTime.tryParse(rawExpiry);
    if (parsed == null) return 420;
    final diff = parsed.toLocal().difference(DateTime.now()).inSeconds;
    if (diff <= 0) return 1;
    return diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _khaltiLinkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPendingKhaltiPayment(trigger: 'resume');
    }
  }

  Future<void> _listenForKhaltiCallbackLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      _handleKhaltiCallbackUri(initialUri);
    } catch (_) {}

    _khaltiLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleKhaltiCallbackUri,
      onError: (_) {},
    );
  }

  bool _isKhaltiCallbackUri(Uri uri) {
    return uri.scheme == 'futsmandu' && uri.host == 'khalti-callback';
  }

  void _handleKhaltiCallbackUri(Uri? uri) {
    if (uri == null || !_isKhaltiCallbackUri(uri)) return;

    final status = (uri.queryParameters['status'] ?? '').toLowerCase();
    if (status == 'cancelled' || status == 'canceled' || status == 'failed') {
      if (!mounted) return;
      setState(() {
        _isAwaitingKhaltiCallback = false;
        _pendingKhaltiPidx = null;
        _pendingKhaltiBookingId = null;
        _pendingKhaltiArgs = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khalti payment was not completed.')),
      );
      return;
    }

    _verifyPendingKhaltiPayment(trigger: 'deeplink');
  }

  Future<void> _verifyPendingKhaltiPayment({required String trigger}) async {
    if (!mounted || !_isAwaitingKhaltiCallback || _isVerifyingKhaltiCallback) {
      return;
    }

    final pidx = _pendingKhaltiPidx;
    final bookingId = _pendingKhaltiBookingId;
    final args = _pendingKhaltiArgs;
    if (pidx == null || pidx.isEmpty || bookingId == null || bookingId.isEmpty) {
      return;
    }

    setState(() {
      _isVerifyingKhaltiCallback = true;
      _loading = true;
    });

    try {
      final verification =
          await _paymentsService.verifyKhalti(pidx: pidx, bookingId: bookingId);
      if (!mounted) return;

      setState(() {
        _isAwaitingKhaltiCallback = false;
        _pendingKhaltiPidx = null;
        _pendingKhaltiBookingId = null;
        _pendingKhaltiArgs = null;
      });

      _goToConfirmation(args, verification: verification, gateway: 'KHALTI');
    } on PaymentsApiException catch (e) {
      if (!mounted) return;
      if (trigger == 'resume') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waiting for Khalti confirmation: ${e.message}')),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to verify Khalti payment yet.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isVerifyingKhaltiCallback = false;
        _loading = false;
      });
    }
  }

  double _amountFromArgs(Map<String, dynamic>? args) {
    final heldAmount = args?['heldBooking']?['total_amount'];
    if (heldAmount is num) return heldAmount.toDouble() / 100.0;

    final heldAmountString = args?['heldBooking']?['total_amount']?.toString();
    if (heldAmountString != null) {
      final parsed = double.tryParse(heldAmountString);
      if (parsed != null) return parsed / 100.0;
    }

    final price = args?['slot']?['price'];
    if (price is num) return price.toDouble();
    return double.tryParse(price?.toString() ?? '') ?? 1800.0;
  }

  String _bookingId(Map<String, dynamic>? args) {
    final heldBooking = args?['heldBooking'];
    if (heldBooking is Map && heldBooking['id'] is String) {
      return heldBooking['id'] as String;
    }
    return '';
  }

  Future<void> _onPayPressed(Map<String, dynamic>? args) async {
    if (_gateway == 'khalti' && _isAwaitingKhaltiCallback) {
      await _verifyPendingKhaltiPayment(trigger: 'manual-check');
      return;
    }

    final bookingId = _bookingId(args);

    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking hold not found. Please retry.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_gateway == 'esewa') {
        await _paymentsService.initiateEsewa(bookingId: bookingId);

        final config = ESewaConfig.dev(
          amount: _amountFromArgs(args),
          successUrl: EsewaPaymentConfig.devSuccessUrl,
          failureUrl: EsewaPaymentConfig.devFailureUrl,
          secretKey: EsewaPaymentConfig.secretKey,
          transactionUuid: bookingId,
        );

        final result =
            await Esewa.i.init(context: context, eSewaConfig: config);
        if (!mounted) return;

        if (!result.hasData || result.data == null) {
          final message = result.error ?? 'Payment failed';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          return;
        }

        final base64Payload = result.data!.data ?? '';
        if (base64Payload.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('eSewa callback data is missing. Please try again.'),
            ),
          );
          return;
        }

        if (kDebugMode) {
          debugPrint('eSewa success payload (base64): $base64Payload');
        }

        final verification =
            await _paymentsService.verifyEsewa(data: base64Payload);

        _goToConfirmation(args, verification: verification, gateway: 'ESEWA');
        return;
      }

      final init = await _paymentsService.initiateKhalti(bookingId: bookingId);
      final paymentUrl = init['payment_url']?.toString() ?? '';
      final pidx = init['pidx']?.toString() ?? '';

      if (paymentUrl.isEmpty || pidx.isEmpty) {
        throw const PaymentsApiException(
          message: 'Khalti initiation response is incomplete.',
          statusCode: 500,
        );
      }

      setState(() {
        _pendingKhaltiPidx = pidx;
        _pendingKhaltiBookingId = bookingId;
        _pendingKhaltiArgs = args;
        _isAwaitingKhaltiCallback = true;
      });

      final opened = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;
      if (!opened) {
        setState(() {
          _isAwaitingKhaltiCallback = false;
          _pendingKhaltiPidx = null;
          _pendingKhaltiBookingId = null;
          _pendingKhaltiArgs = null;
        });
        throw const PaymentsApiException(
          message: 'Could not open Khalti payment page.',
          statusCode: 500,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete payment in Khalti and return to this app.'),
        ),
      );
      return;
    } on PaymentsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToConfirmation(
    Map<String, dynamic>? args, {
    required Map<String, dynamic> verification,
    required String gateway,
  }) {
    Navigator.pushReplacementNamed(
      context,
      '/booking-confirm',
      arguments: {
        'slot': args?['slot'],
        'venue': args?['venue'],
        'heldBooking': args?['heldBooking'],
        'bookingDate': args?['bookingDate'],
        'startTime': args?['startTime'],
        'endTime': args?['endTime'],
        'paymentGateway': gateway,
        'verification': verification,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerText =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    final isUrgent = _seconds < 60;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final heldBooking = args?['heldBooking'] is Map
        ? (args?['heldBooking'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final totalAmount =
        heldBooking['displayAmount']?.toString().isNotEmpty == true
            ? heldBooking['displayAmount'].toString()
            : heldBooking['total_amount']?.toString() ??
                args?['slot']?['price']?.toString() ??
                '1800';

    final selectedCourtName = args?['venue']?['courts'] is List &&
            args?['courtIdx'] is int &&
            (args?['venue']?['courts'] as List).length >
                (args?['courtIdx'] as int)
        ? ((args?['venue']?['courts'] as List)[args?['courtIdx'] as int]['name']
                ?.toString() ??
            'Court')
        : 'Court';
    final bookingDate = args?['bookingDate']?.toString() ?? '-';
    final startTime = args?['startTime']?.toString() ?? '-';
    final endTime = args?['endTime']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Complete Payment', style: AppText.h3),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs2),
            child: Center(
              child: _TimerPill(text: timerText, urgent: isUrgent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutsCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Booking Summary', style: AppText.h3),
                  const SizedBox(height: 10),
                  Divider(height: 20, color: AppColors.borderClr),
                  _SumRow(
                      'Venue', args?['venue']?['name'] ?? 'Futsmandu Arena'),
                  _SumRow('Court', selectedCourtName),
                  _SumRow('Date', bookingDate),
                  _SumRow('Time', '$startTime - $endTime'),
                  const _SumRow('Duration', '60 minutes'),
                  Divider(height: 20, color: AppColors.borderClr),
                  Row(
                    children: [
                      Text('Total Amount',
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        'NPR $totalAmount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Spacer(),
                      Text('Hold fee NPR 20 (non-refundable)',
                          style: AppText.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Choose Payment Method', style: AppText.h3),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PaymentCard(
                    id: 'khalti',
                    name: 'Khalti',
                    brandColor: AppColors.khalti,
                    selected: _gateway,
                    onSelect: (id) => setState(() => _gateway = id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentCard(
                    id: 'esewa',
                    name: 'eSewa',
                    brandColor: AppColors.esewa,
                    selected: _gateway,
                    onSelect: (id) => setState(() => _gateway = id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs2,
                vertical: AppSpacing.xs2,
              ),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border(left: BorderSide(color: AppColors.blue, width: 3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAwaitingKhaltiCallback
                          ? 'Waiting for Khalti callback. We will verify automatically when you return.'
                          : 'You will be redirected to the payment page. Return to auto-verify and confirm your booking.',
                      style: AppText.bodySm.copyWith(color: AppColors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FutsButton(
              label: _gateway == 'khalti' && _isAwaitingKhaltiCallback
                  ? 'Check Khalti Payment Status'
                  : 'Pay NPR $totalAmount',
              isLoading: _loading,
              onPressed: _gateway == null ? null : () => _onPayPressed(args),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String text;
  final bool urgent;

  const _TimerPill({required this.text, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.red : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: AppTextStyles.semiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;

  const _SumRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: AppText.bodySm),
          const Spacer(),
          Text(value,
              style: AppText.bodySm.copyWith(color: AppColors.txtPrimary)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String id;
  final String name;
  final Color brandColor;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _PaymentCard({
    required this.id,
    required this.name,
    required this.brandColor,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == id;
    return GestureDetector(
      onTap: () => onSelect(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 88,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs3,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor.withValues(alpha: 0.08)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandColor : AppColors.borderClr,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 26,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: AppTextStyles.semiBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(name, style: AppText.label),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle_rounded,
                    size: 18, color: brandColor),
              ),
          ],
        ),
      ),
    );
  }
}
