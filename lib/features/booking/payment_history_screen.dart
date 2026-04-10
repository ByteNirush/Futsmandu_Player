import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/models/payment_models.dart';
import 'presentation/providers/payment_controllers.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return AppColors.green;
      case 'INITIATED':
      case 'PENDING':
        return AppColors.amber;
      case 'FAILED':
        return AppColors.red;
      default:
        return AppColors.txtDisabled;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Completed';
      case 'INITIATED':
        return 'Processing';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  String _gatewayLabel(String gateway) {
    final normalized = gateway.toUpperCase();
    return normalized == 'KHALTI'
        ? 'Khalti'
        : normalized == 'ESEWA'
            ? 'eSewa'
            : gateway;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr is! String || dateStr.isEmpty) return '-';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return '${parsed.day} ${_monthAbbr(parsed.month)} ${parsed.year}';
  }

  String _monthAbbr(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Payment History', style: AppText.h2),
        elevation: 0,
        backgroundColor: AppColors.bgPrimary,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(paymentHistoryControllerProvider.notifier)
                .refreshHistory(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(),
                  style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref
                    .read(paymentHistoryControllerProvider.notifier)
                    .refreshHistory(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.wallet_outlined,
                title: 'No Payments Yet',
                subtitle:
                    'Book a court to make your first payment here will appear',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _PaymentHistoryCard(
              payment: payments[i],
              statusColor: _statusColor(payments[i].status),
              statusLabel: _statusLabel(payments[i].status),
              gatewayLabel: _gatewayLabel(payments[i].gateway),
              formatDate: _formatDate,
            ),
          );
        },
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentHistoryItem payment;
  final Color statusColor;
  final String statusLabel;
  final String gatewayLabel;
  final String Function(dynamic) formatDate;

  const _PaymentHistoryCard({
    required this.payment,
    required this.statusColor,
    required this.statusLabel,
    required this.gatewayLabel,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final venueName = payment.booking.venueName.isEmpty
      ? 'Court'
      : payment.booking.venueName;
    final courtName =
      payment.booking.courtName.isEmpty ? '-' : payment.booking.courtName;
    final bookingDate = payment.booking.bookingDate;
    final startTime = payment.booking.startTime.isEmpty
      ? '-'
      : payment.booking.startTime;
    final amount =
      payment.displayAmount.isEmpty ? payment.amount.toString() : payment.displayAmount;

    return FutsCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venueName,
                        style: AppText.bodySm
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$courtName • $startTime',
                        style: AppText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('NPR $amount',
                      style: AppText.bodySm.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.green)),
                  const SizedBox(height: 2),
                  StatusBadge(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.txtDisabled),
              const SizedBox(width: 6),
              Text(formatDate(bookingDate), style: AppText.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(gatewayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.txtDisabled,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
