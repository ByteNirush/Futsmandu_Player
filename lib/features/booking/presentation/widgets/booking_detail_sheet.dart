import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../data/models/booking_models.dart';
import '../providers/booking_controllers.dart';
import 'cancel_booking_sheet.dart';

class BookingDetailSheet extends ConsumerWidget {
  const BookingDetailSheet({
    super.key,
    required this.bookingId,
    required this.bookingItem,
  });

  final String bookingId;
  final BookingHistoryItem bookingItem;

  bool _isCancellableStatus(String? status) {
    final normalized = (status ?? '').toUpperCase();
    return normalized == 'CONFIRMED' || normalized == 'HELD';
  }

  void _showCancelSheet(BuildContext context) {
    Navigator.pop(context); // Close detail sheet first
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return CancelBookingSheet(booking: bookingItem);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookingDetailProvider(bookingId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) {
            final message = error.toString().replaceFirst('Exception: ', '');
            return SizedBox(
              height: 260,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    message.isNotEmpty
                        ? message
                        : 'Could not load booking detail.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
          data: (detail) {
            final booking = detail.raw;
            final court = booking['court'] is Map
                ? (booking['court'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final venue = court['venue'] is Map
                ? (court['venue'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final isCancellable =
                _isCancellableStatus(booking['status']?.toString());
            final isPartialTeam =
                booking['booking_type']?.toString() == 'PARTIAL_TEAM';

            final matchGroup = booking['match_group'] is Map
                ? (booking['match_group'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final matchGroupId = matchGroup['id']?.toString().isNotEmpty == true
                ? matchGroup['id'].toString()
                : booking['match_group_id']?.toString() ?? '';
            final maxPlayers = booking['max_players'] is int
                ? booking['max_players'] as int
                : 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderClr,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Booking Detail',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow('Booking ID', booking['id']?.toString() ?? '-'),
                _DetailRow(
                  'Status',
                  (booking['status']?.toString().toUpperCase() == 'HELD')
                      ? 'Confirmed'
                      : (booking['status']?.toString() ?? '-'),
                ),
                _DetailRow(
                  'Type',
                  isPartialTeam ? 'Partial Team (Open Match)' : 'Full Team',
                ),
                _DetailRow('Venue', venue['name']?.toString() ?? '-'),
                _DetailRow('Court', court['name']?.toString() ?? '-'),
                _DetailRow('Date', booking['booking_date']?.toString() ?? '-'),
                _DetailRow(
                  'Time',
                  formatClockTimeRange12Hour(
                    booking['start_time']?.toString() ?? '',
                    booking['end_time']?.toString() ?? '',
                  ),
                ),
                if (isPartialTeam && maxPlayers > 0)
                  _DetailRow('Team Size', '$maxPlayers players total'),
                _DetailRow(
                  'Amount',
                  booking['displayAmount']?.toString() ??
                      'NPR ${booking['total_amount'] ?? 0}',
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isPartialTeam && matchGroupId.isNotEmpty) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue.withValues(alpha: 0.1),
                      foregroundColor: AppColors.blue,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/match-detail',
                        arguments: {'id': matchGroupId},
                      );
                    },
                    child: const Text('View Match Group'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (isCancellable) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => _showCancelSheet(context),
                    child: const Text('Cancel Booking'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.txtDisabled),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
