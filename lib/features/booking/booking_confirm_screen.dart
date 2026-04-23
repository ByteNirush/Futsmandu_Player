import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen>
    with SingleTickerProviderStateMixin {
  bool _show = false;
  late AnimationController _confettiController;

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

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final heldBooking = args?['heldBooking'] is Map
        ? (args?['heldBooking'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

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
    final totalAmount =
        heldBooking['displayAmount']?.toString().isNotEmpty == true
            ? heldBooking['displayAmount'].toString()
            : heldBooking['total_amount']?.toString() ??
                args?['slot']?['price']?.toString() ??
                '1800';
    final verification = args?['verification'] is Map
        ? (args?['verification'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final confirmed = verification['confirmed'] is Map
        ? (verification['confirmed'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final matchGroup = verification['matchGroup'] is Map
        ? (verification['matchGroup'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final matchGroupId = matchGroup['id']?.toString() ?? '';
    final gateway = args?['paymentGateway']?.toString() ?? '';
    final amountLabel = _formattedAmountLabel(totalAmount);
    final paymentLabel = gateway.isNotEmpty
        ? '${gateway.toUpperCase()} paid $amountLabel'
        : 'Paid $amountLabel';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // CONFETTI
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return Stack(
                children: List.generate(
                    22, (index) => _ConfettiItem(index, _confettiController)),
              );
            },
          ),
          // CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kNavBarHeight,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Center(
                  child: AnimatedScale(
                    scale: _show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green.withValues(alpha: 0.10),
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      child: Center(
                        child: Icon(Icons.check_rounded,
                            size: 60, color: AppColors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedOpacity(
                  opacity: _show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      Text('Booking Confirmed!',
                          style: AppText.h1, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'Your slot is locked in. See you on the pitch!',
                        style:
                            AppText.body.copyWith(color: AppColors.txtDisabled),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FutsCard(
                        child: Column(
                          children: [
                            _ConfirmRow('Venue',
                                args?['venue']?['name'] ?? 'Futsmandu Arena'),
                            _ConfirmRow('Court', selectedCourtName),
                            _ConfirmRow('Date', bookingDate),
                            _ConfirmRow('Time', '$startTime - $endTime'),
                            const Divider(),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 380;

                                final matchGroupInfo = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Match Group', style: AppText.bodySm),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.group_outlined,
                                            size: 15, color: AppColors.blue),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            matchGroupId.isNotEmpty
                                                ? 'Created and ready to join'
                                                : 'Preparing match group',
                                            style: AppText.bodySm.copyWith(
                                                color: AppColors.blue),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );

                                final paymentInfo = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 15, color: AppColors.green),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        paymentLabel,
                                        style: AppText.mono.copyWith(
                                          fontSize: 14,
                                          color: AppColors.green,
                                          fontWeight: AppTextStyles.semiBold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: compact
                                            ? TextAlign.left
                                            : TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      matchGroupInfo,
                                      const SizedBox(height: 8),
                                      paymentInfo,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: matchGroupInfo),
                                    const SizedBox(width: 12),
                                    Flexible(child: paymentInfo),
                                  ],
                                );
                              },
                            ),
                            if (confirmed['id'] != null) ...[
                              const SizedBox(height: 8),
                              _ConfirmRow(
                                'Booking ID',
                                confirmed['id']?.toString() ?? '-',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FutsButton(
                        label: 'View Match Group',
                        onPressed: matchGroupId.isEmpty
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/match-detail',
                                  arguments: {'id': matchGroupId},
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      FutsButton(
                        label: 'Back to Home',
                        outlined: true,
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (_) => false);
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.txtDisabled),
                          label: Text('Add to Calendar', style: AppText.bodySm),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Calendar feature coming soon')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: AppText.bodySm),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppText.bodySm.copyWith(color: AppColors.txtPrimary),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiItem extends StatelessWidget {
  final int index;
  final Animation<double> animation;

  const _ConfettiItem(this.index, this.animation);

  @override
  Widget build(BuildContext context) {
    final rand = math.Random(index);
    final double startX = rand.nextDouble();
    final List<Color> colors = [
      AppColors.green,
      AppColors.amber,
      AppColors.blue,
      AppColors.red,
      Colors.white.withValues(alpha: 0.6),
    ];
    final Color color = colors[index % 5];
    final double rotSpeed = index * 0.7;
    final double fallSpeedFactor = 0.8 + (rand.nextDouble() * 0.4);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final top = -20 + (animation.value * screenHeight * 0.6 * fallSpeedFactor);
    final left = startX * screenWidth;

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: animation.value * rotSpeed * 6.28,
        child: Container(
          width: 7,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
