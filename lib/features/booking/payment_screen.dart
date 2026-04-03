import 'dart:async';

import 'package:esewa_flutter/esewa_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/esewa_payment_config.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _gateway;
  int _seconds = 420;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _amountFromArgs(Map<String, dynamic>? args) {
    final price = args?['slot']?['price'];
    if (price is num) return price.toDouble();
    return double.tryParse(price?.toString() ?? '') ?? 1800.0;
  }

  Future<void> _onPayPressed(Map<String, dynamic>? args) async {
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      if (_gateway == 'esewa') {
        final config = ESewaConfig.dev(
          amount: _amountFromArgs(args),
          successUrl: EsewaPaymentConfig.devSuccessUrl,
          failureUrl: EsewaPaymentConfig.devFailureUrl,
          secretKey: EsewaPaymentConfig.secretKey,
          transactionUuid: 'FM-${DateTime.now().millisecondsSinceEpoch}',
        );

        final result =
            await Esewa.i.init(context: context, eSewaConfig: config);
        if (!mounted) return;

        if (result.hasData && result.data != null) {
          final base64Payload = result.data!.data ?? '';
          if (kDebugMode) {
            debugPrint('eSewa success payload (base64): $base64Payload');
          }
          navigator.pushReplacementNamed(
            '/booking-confirm',
            arguments: {
              'slot': args?['slot'],
              'venue': args?['venue'],
            },
          );
        } else {
          final message = result.error ?? 'Payment failed';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }

      // Khalti (or other gateways): placeholder until integrated
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      navigator.pushReplacementNamed(
        '/booking-confirm',
        arguments: {
          'slot': args?['slot'],
          'venue': args?['venue'],
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerText =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    final isUrgent = _seconds < 60;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;

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
                  const _SumRow('Court', 'Court A · 5v5 Turf'),
                  const _SumRow('Date', 'Sat 14 Oct 2025'),
                  const _SumRow('Time', '17:00 – 18:00'),
                  const _SumRow('Duration', '60 minutes'),
                  Divider(height: 20, color: AppColors.borderClr),
                  Row(
                    children: [
                      Text('Total Amount',
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        'NPR ${args?['slot']?['price'] ?? 1800}',
                        style: GoogleFonts.barlow(
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
                      'You will be redirected to the payment page. Do not close the app.',
                      style: AppText.bodySm.copyWith(color: AppColors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FutsButton(
              label: 'Pay NPR ${args?['slot']?['price'] ?? 1800}',
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
            style: GoogleFonts.barlow(
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
                        style: GoogleFonts.barlow(
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
