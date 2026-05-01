import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../shared/widgets/futs_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/booking_models.dart';

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
    this.onJoin,
    this.onViewMatch,
  });

  final BookingHistoryItem booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onJoin;
  final VoidCallback? onViewMatch;

  @override
  Widget build(BuildContext context) {
    final amount = booking.displayAmount.isNotEmpty
        ? booking.displayAmount
        : 'NPR ${booking.priceNpr}';
        
    final isConfirmed = booking.status.toUpperCase() == 'HELD';
    final statusLabel = isConfirmed ? 'Confirmed' : booking.status;
    final statusColor = AppColors.statusColor(isConfirmed ? 'CONFIRMED' : booking.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: FutsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.venueName.isNotEmpty ? booking.venueName : '-',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.courtName.isNotEmpty ? booking.courtName : '-',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: statusLabel,
                      color: statusColor,
                    ),
                    if (booking.isPartialTeam) ...[
                      const SizedBox(height: 4),
                      const StatusBadge(
                        label: 'Partial Team',
                        color: AppColors.blue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (booking.isPartialTeam && booking.maxPlayers > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_add_rounded,
                        size: 14, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text(
                      booking.playersNeeded > 0
                          ? 'Need ${booking.playersNeeded} more players  •  ${booking.myPlayers} of ${booking.maxPlayers} joined'
                          : 'Team full  •  ${booking.maxPlayers}/${booking.maxPlayers} players',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.green,
                            fontWeight: AppFontWeights.semiBold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Meta(Icons.calendar_today, booking.date.isNotEmpty ? booking.date : booking.bookingDate),
                _Meta(Icons.access_time, _formatTime(booking)),
                _Meta(Icons.timelapse_outlined, booking.duration.isNotEmpty ? booking.duration : '-'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                    color: AppColors.txtPrimary,
                  ),
                ),
                const Spacer(),
                if (onViewMatch != null)
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.blue),
                        foregroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: onViewMatch,
                      child: const Text('View Match'),
                    ),
                  ),
                if (onViewMatch != null && onJoin != null)
                  const SizedBox(width: AppSpacing.xs),
                if (onJoin != null)
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.green),
                        foregroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: onJoin,
                      child: const Text('Join'),
                    ),
                  ),
                if (onCancel != null && (onJoin != null || onViewMatch != null))
                  const SizedBox(width: AppSpacing.xs),
                if (onCancel != null)
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.red),
                        foregroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BookingHistoryItem item) {
    if (item.time.isNotEmpty && item.time != '-') return item.time;
    if (item.startTime.isEmpty && item.endTime.isEmpty) return '-';
    if (item.endTime.isEmpty) return item.startTime;
    return '${item.startTime} - ${item.endTime}';
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.txtDisabled),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: AppFontWeights.semiBold,
                color: AppColors.txtPrimary,
              ),
        ),
      ],
    );
  }
}
