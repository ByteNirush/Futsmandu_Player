import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/utils/time_formatters.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../shared/widgets/futs_card.dart';
import '../../data/models/booking_models.dart';

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final BookingHistoryItem booking;
  final VoidCallback onTap;

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 3) {
        return '${parts[0]} ${parts[1]} ${parts[2]}';
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(BookingHistoryItem item) {
    if (item.time.isNotEmpty && item.time != '-') return item.time;
    if (item.startTime.isEmpty && item.endTime.isEmpty) return '-';
    return formatClockTimeRange12Hour(item.startTime, item.endTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final amount = booking.displayAmount.isNotEmpty
        ? booking.displayAmount
        : 'NPR ${booking.priceNpr}';

    final isConfirmed = booking.status.toUpperCase() == 'HELD';
    final statusLabel = isConfirmed ? 'Confirmed' : booking.status;
    final statusColor =
        AppColors.statusColor(isConfirmed ? 'CONFIRMED' : booking.status);

    return FutsCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Middle Details Block (now Left side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  booking.venueName.isNotEmpty ? booking.venueName : '-',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  booking.courtName.isNotEmpty ? booking.courtName : '-',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (booking.id.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Booking ID: ${booking.id}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (booking.isPartialTeam) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Partial Team',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.blue,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Right Value & Status Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusLabel.toLowerCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: AppFontWeights.medium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatDate(booking.date.isNotEmpty
                    ? booking.date
                    : booking.bookingDate),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatTime(booking),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
