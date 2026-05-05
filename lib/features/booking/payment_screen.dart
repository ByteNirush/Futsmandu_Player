import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/esewa_payment_config.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../core/utils/time_formatters.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import 'data/services/player_payments_service.dart';
import 'presentation/providers/payment_controllers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  // Temporary dev switch: bypass external payment gateways.
  static const bool _bypassGatewayPayment = true;

  final AppLinks _appLinks = AppLinks();

  String? _gateway;
  StreamSubscription<Uri>? _khaltiLinkSubscription;

  String? _pendingKhaltiPidx;
  String? _pendingKhaltiBookingId;
  Map<String, dynamic>? _pendingKhaltiArgs;
  bool _isAwaitingKhaltiCallback = false;
  bool _isVerifyingKhaltiCallback = false;

  bool get _loading => ref.watch(paymentActionControllerProvider).isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForKhaltiCallbackLinks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
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
    if (pidx == null ||
        pidx.isEmpty ||
        bookingId == null ||
        bookingId.isEmpty) {
      return;
    }

    setState(() {
      _isVerifyingKhaltiCallback = true;
    });

    try {
      final verification =
          await ref.read(paymentActionControllerProvider.notifier).verifyKhalti(
                pidx: pidx,
                bookingId: bookingId,
              );
      if (!mounted) return;

      setState(() {
        _isAwaitingKhaltiCallback = false;
        _pendingKhaltiPidx = null;
        _pendingKhaltiBookingId = null;
        _pendingKhaltiArgs = null;
      });

      _goToConfirmation(
        args,
        verification: verification.toMap(),
        gateway: 'KHALTI',
      );
    } on PaymentsApiException catch (e) {
      if (!mounted) return;
      if (trigger == 'resume') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Waiting for Khalti confirmation: ${e.message}')),
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
      if (mounted) {
        setState(() {
          _isVerifyingKhaltiCallback = false;
        });
      }
    }
  }

  double _amountFromArgs(Map<String, dynamic>? args) {
    final bookingRecord = args?['bookingRecord'];
    if (bookingRecord is Map && bookingRecord['total_amount'] is num) {
      return bookingRecord['total_amount'].toDouble() / 100.0;
    }

    final bookingAmountString =
        args?['bookingRecord']?['total_amount']?.toString();
    if (bookingAmountString != null) {
      final parsed = double.tryParse(bookingAmountString);
      if (parsed != null) return parsed / 100.0;
    }

    final price = args?['slot']?['price'];
    if (price is num) return price.toDouble() / 100.0;
    final parsed = double.tryParse(price?.toString() ?? '');
    return (parsed != null) ? parsed / 100.0 : 1800.0;
  }

  String _bookingId(Map<String, dynamic>? args) {
    final bookingRecord = args?['bookingRecord'];
    if (bookingRecord is Map && bookingRecord['id'] is String) {
      return bookingRecord['id'] as String;
    }
    return '';
  }

  String _formattedAmountLabel(String amount) {
    final normalized = amount.trim();
    if (normalized.isEmpty) return 'NPR 0';

    final upper = normalized.toUpperCase();
    if (upper.startsWith('NPR ')) return normalized;
    if (upper.startsWith('RS ')) {
      return 'NPR ${normalized.substring(3).trim()}';
    }

    return 'NPR $normalized';
  }

  String _selectedGatewayCode() {
    if (_gateway == 'esewa') return 'ESEWA';
    return 'KHALTI';
  }

  Future<void> _onPayPressed(Map<String, dynamic>? args) async {
    if (_gateway == 'khalti' && _isAwaitingKhaltiCallback) {
      await _verifyPendingKhaltiPayment(trigger: 'manual-check');
      return;
    }

    final bookingId = _bookingId(args);

    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking not found. Please retry.')),
      );
      return;
    }

    if (_bypassGatewayPayment) {
      Map<String, dynamic> initiation = const <String, dynamic>{};
      try {
        if (_gateway == 'esewa') {
          final result = await ref
              .read(paymentActionControllerProvider.notifier)
              .initiateEsewa(bookingId: bookingId);
          initiation = result.raw;
        } else {
          final result = await ref
              .read(paymentActionControllerProvider.notifier)
              .initiateKhalti(bookingId: bookingId);
          initiation = {
            'paymentUrl': result.paymentUrl,
            'pidx': result.pidx,
          };
        }
      } catch (_) {
        // In bypass mode, continue even if external gateway initialization fails.
      }

      _goToConfirmation(
        args,
        verification: {
          'confirmed': {
            'id': bookingId,
            'status': 'PENDING_PAYMENT',
          },
          'matchGroup': {},
          'payment': {
            'status': 'INITIATED',
            'gateway': _selectedGatewayCode(),
            ...initiation,
          },
          'bypassed': true,
        },
        gateway: _selectedGatewayCode(),
      );
      return;
    }

    try {
      if (_gateway == 'esewa') {
        await ref
            .read(paymentActionControllerProvider.notifier)
            .initiateEsewa(bookingId: bookingId);
        if (!mounted) return;

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

        final verification = await ref
            .read(paymentActionControllerProvider.notifier)
            .verifyEsewa(data: base64Payload);

        _goToConfirmation(
          args,
          verification: verification.toMap(),
          gateway: 'ESEWA',
        );
        return;
      }

      final init = await ref
          .read(paymentActionControllerProvider.notifier)
          .initiateKhalti(bookingId: bookingId);
      final paymentUrl = init.paymentUrl;
      final pidx = init.pidx;

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
        'bookingRecord': args?['bookingRecord'],
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
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final bookingRecord = args?['bookingRecord'] is Map
        ? (args?['bookingRecord'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    // Determine the amount to display
    String totalAmount;
    if (bookingRecord['displayAmount']?.toString().isNotEmpty == true) {
      totalAmount = bookingRecord['displayAmount'].toString();
    } else if (bookingRecord['total_amount'] != null) {
      totalAmount = bookingRecord['total_amount'].toString();
    } else {
      // Fallback to slot price — convert from paisa (NPR × 100) to NPR
      final slotPrice = args?['slot']?['price'];
      if (slotPrice is num) {
        totalAmount = (slotPrice / 100.0).toStringAsFixed(0);
      } else {
        final parsed = double.tryParse(slotPrice?.toString() ?? '');
        totalAmount = parsed != null ? (parsed / 100.0).toStringAsFixed(0) : '1800';
      }
    }
    final amountLabel = _formattedAmountLabel(totalAmount);

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
        title: Text('Complete Payment',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: AppFontWeights.bold)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutsCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Booking Summary',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: 10),
                  Divider(height: 20, color: AppColors.borderClr),
                  _SumRow(
                      'Venue', args?['venue']?['name'] ?? 'Futsmandu Arena'),
                  _SumRow('Court', selectedCourtName),
                  _SumRow('Date', bookingDate),
                  _SumRow(
                    'Time',
                    formatClockTimeRange12Hour(startTime, endTime),
                  ),
                  const _SumRow('Duration', '60 minutes'),
                  Divider(height: 20, color: AppColors.borderClr),
                  Row(
                    children: [
                      Text('Total Amount',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: AppFontWeights.semiBold)),
                      const Spacer(),
                      Text(
                        amountLabel,
                        style: AppTypography.textTheme(
                          Theme.of(context).colorScheme,
                        ).titleSmall?.copyWith(
                              fontWeight: AppFontWeights.semiBold,
                              color: AppColors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Spacer(),
                      Text('Booking fee NPR 20 (non-refundable)',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: AppFontWeights.semiBold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Choose Payment Method',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: AppFontWeights.bold)),
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
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                    left: BorderSide(color: AppColors.blue, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bypassGatewayPayment
                          ? 'Temporary bypass is enabled. Selecting a payment method and tapping pay will confirm instantly.'
                          : _isAwaitingKhaltiCallback
                              ? 'Waiting for Khalti callback. We will verify automatically when you return.'
                              : 'You will be redirected to the payment page. Return to auto-verify and confirm your booking.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FutsButton(
              label: !_bypassGatewayPayment &&
                      _gateway == 'khalti' &&
                      _isAwaitingKhaltiCallback
                  ? 'Check Khalti Payment Status'
                  : 'Pay $amountLabel',
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

class _SumRow extends StatelessWidget {
  final String label;
  final String value;

  const _SumRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.txtPrimary)),
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
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
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
                        style: AppTypography.textTheme(
                          Theme.of(context).colorScheme,
                        ).labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: AppFontWeights.semiBold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontWeight: AppFontWeights.semiBold)),
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
