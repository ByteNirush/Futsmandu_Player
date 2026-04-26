import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/enhanced_empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/models/booking_models.dart';
import 'presentation/providers/booking_controllers.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _contentHorizontalPadding = AppSpacing.sm;

  static const List<String> _filters = <String>[
    'All',
    'Confirmed',
    'Completed',
    'Cancelled',
    'Held',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(bookingHistoryControllerProvider.notifier).loadMore();
    }
  }

  bool _isCancellableStatus(String? status) {
    final normalized = (status ?? '').toUpperCase();
    return normalized == 'CONFIRMED' || normalized == 'HELD';
  }

  Future<void> _showCancelSheet(BookingHistoryItem booking) async {
    final reasonController = TextEditingController();
    bool isCancelling = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
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
                  const SizedBox(height: AppSpacing.md),
                  Text('Cancel Booking?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(booking.venueName, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtPrimary),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Let the venue know why you are cancelling...',
                      alignLabelWithHint: true,
                      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: AppFontWeights.semiBold),
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtDisabled),
                      filled: true,
                      fillColor: AppColors.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCancelling
                              ? null
                              : () => Navigator.pop(sheetContext),
                          child: const Text('Keep Booking'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.red.withValues(alpha: 0.1),
                            foregroundColor: AppColors.red,
                          ),
                          onPressed: isCancelling
                              ? null
                              : () async {
                                  // Show confirmation dialog
                                  final shouldCancel = await showDialog<bool>(
                                        context: sheetContext,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text(
                                              'Confirm Cancellation'),
                                          content: const Text(
                                            'Are you sure you want to cancel this booking? This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  dialogContext, false),
                                              child: const Text('Keep Booking'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.red,
                                              ),
                                              onPressed: () => Navigator.pop(
                                                  dialogContext, true),
                                              child:
                                                  const Text('Cancel Booking'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (!shouldCancel) return;

                                  setSheetState(() => isCancelling = true);
                                  try {
                                    final response = await ref
                                        .read(bookingHistoryControllerProvider
                                            .notifier)
                                        .cancelBooking(
                                          bookingId: booking.id,
                                          reason: reasonController.text,
                                        );
                                    if (!mounted) return;

                                    Navigator.of(this.context).pop();
                                    final refundText =
                                        response.displayRefund.isNotEmpty
                                            ? response.displayRefund
                                            : 'NPR ${response.refundAmount}';
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Booking cancelled. Refund: $refundText',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is Exception
                                              ? e.toString().replaceFirst(
                                                  'Exception: ', '')
                                              : 'Could not cancel booking right now.',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setSheetState(() => isCancelling = false);
                                    }
                                  }
                                },
                          child: isCancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Cancel & Refund'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBookingDetail(String bookingId) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ref
              .read(bookingDetailProvider(bookingId).future)
              .then((v) => v.raw),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              final message = snapshot.error?.toString() ??
                  'Could not load booking detail.';

              return SizedBox(
                height: 260,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(message,
                        style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  ),
                ),
              );
            }

            final booking = snapshot.data ?? const <String, dynamic>{};
            final court = booking['court'] is Map
                ? (booking['court'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final venue = court['venue'] is Map
                ? (court['venue'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final payment = booking['payment'] is Map
                ? (booking['payment'] as Map).cast<String, dynamic>()
                : const <String, dynamic>{};
            final isCancellable =
                _isCancellableStatus(booking['status']?.toString());

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
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
                    const SizedBox(height: AppSpacing.md),
                    Text('Booking Detail', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: AppFontWeights.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow('Booking ID', booking['id']?.toString() ?? '-'),
                    _DetailRow('Status', booking['status']?.toString() ?? '-'),
                    _DetailRow('Venue', venue['name']?.toString() ?? '-'),
                    _DetailRow('Court', court['name']?.toString() ?? '-'),
                    _DetailRow(
                        'Date', booking['booking_date']?.toString() ?? '-'),
                    _DetailRow(
                      'Time',
                      '${booking['start_time'] ?? '-'} - ${booking['end_time'] ?? '-'}',
                    ),
                    _DetailRow(
                      'Amount',
                      booking['displayAmount']?.toString() ??
                          'NPR ${booking['total_amount'] ?? 0}',
                    ),
                    _DetailRow('Payment', payment['status']?.toString() ?? '-'),
                    _DetailRow(
                        'Gateway', payment['gateway']?.toString() ?? '-'),
                    const SizedBox(height: AppSpacing.md),
                    if (isCancellable) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor:
                              Theme.of(sheetContext).colorScheme.onError,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          final item = BookingHistoryItem.fromMap({
                            'id': booking['id'],
                            'status': booking['status'],
                            'date': _dateForCard(booking),
                            'time': _timeForCard(booking),
                            'duration': _durationForCard(booking),
                            'priceNPR': _priceForCard(booking),
                            'displayAmount': booking['displayAmount'],
                            'venueName': _venueNameForCard(booking, venue),
                            'courtName': _courtNameForCard(booking, court),
                            'startTime': booking['start_time'],
                            'endTime': booking['end_time'],
                            'bookingDate': booking['booking_date'],
                            'refundStatus': booking['refund_status'],
                            'refundAmount': booking['refund_amount'],
                            'holdExpiresAt': booking['hold_expires_at'],
                            'paymentGateway': payment['gateway'],
                            'paymentStatus': payment['status'],
                            'venueAddress': venue['address'],
                            'venueId': venue['id'],
                            'courtId': court['id'],
                          });
                          _showCancelSheet(item);
                        },
                        child: const Text('Cancel Booking'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(bookingHistoryControllerProvider);
    final selectedFilter = stateAsync.valueOrNull?.filter ?? 'All';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('My Bookings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppFontWeights.bold)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _contentHorizontalPadding,
              AppSpacing.xs,
              _contentHorizontalPadding,
              AppSpacing.xs,
            ),
            child: FilterChipRow(
              options: _filters,
              selected: selectedFilter,
              onSelected: (value) {
                ref
                    .read(bookingHistoryControllerProvider.notifier)
                    .setFilter(value);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(bookingHistoryControllerProvider.notifier).refresh(),
              child: _buildContent(stateAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncValue<BookingHistoryState> stateAsync) {
    if (stateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stateAsync.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          _contentHorizontalPadding,
          AppSpacing.lg,
          _contentHorizontalPadding,
          AppSpacing.xl,
        ),
        children: [
          Column(
            children: [
              Text(stateAsync.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () =>
                    ref.read(bookingHistoryControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    }

    final state = stateAsync.value ?? BookingHistoryState.initial();

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          _contentHorizontalPadding,
          AppSpacing.lg,
          _contentHorizontalPadding,
          AppSpacing.xl,
        ),
        children: const [
          EmptyStateWidget(
            type: EmptyStateType.noBookings,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        _contentHorizontalPadding,
        AppSpacing.xs,
        _contentHorizontalPadding,
        AppSpacing.xl,
      ),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs2),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final booking = state.items[index];
        final isCancellable = _isCancellableStatus(booking.status);
        return _BookingCard(
          booking: booking.toMap(),
          onTap: () => _showBookingDetail(booking.id),
          onCancel: isCancellable
              ? () => _showCancelSheet(booking)
              : null,
          onJoin: booking.status == 'OPEN_TO_JOIN'
              ? () async {
                  try {
                    await ref
                        .read(bookingHistoryControllerProvider.notifier)
                        .joinBooking(bookingId: booking.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined booking slot')),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                }
              : null,
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onCancel,
    required this.onJoin,
  });

  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final amount = booking['displayAmount']?.toString().isNotEmpty == true
        ? booking['displayAmount'].toString()
        : 'NPR ${booking['priceNPR'] ?? 0}';

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
                        booking['venueName']?.toString() ?? '-',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(booking['courtName']?.toString() ?? '-',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: booking['status']?.toString() ?? '-',
                  color: AppColors.statusColor(
                      booking['status']?.toString() ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Meta(Icons.calendar_today, booking['date']?.toString() ?? '-'),
                _Meta(Icons.access_time, booking['time']?.toString() ?? '-'),
                _Meta(Icons.timelapse_outlined,
                    booking['duration']?.toString() ?? '-'),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTextStyles.semiBold,
                    color: AppColors.txtPrimary,
                  ),
                ),
                const Spacer(),
                if (onJoin != null)
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.green),
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
                if (onCancel != null && onJoin != null)
                  const SizedBox(width: AppSpacing.xs),
                if (onCancel != null)
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.red),
                        foregroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: onCancel,
                      child: const Text('Cancel Booking'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _dateForCard(Map<String, dynamic> booking) {
  final value = booking['date']?.toString() ?? '';
  if (value.isNotEmpty) return value;
  return booking['booking_date']?.toString() ?? '-';
}

String _timeForCard(Map<String, dynamic> booking) {
  final value = booking['time']?.toString() ?? '';
  if (value.isNotEmpty) return value;
  final start = booking['start_time']?.toString() ?? '';
  final end = booking['end_time']?.toString() ?? '';
  if (start.isEmpty && end.isEmpty) return '-';
  if (end.isEmpty) return start;
  return '$start - $end';
}

String _durationForCard(Map<String, dynamic> booking) {
  final value = booking['duration']?.toString() ?? '';
  if (value.isNotEmpty) return value;
  return '-';
}

String _priceForCard(Map<String, dynamic> booking) {
  final value = booking['priceNPR']?.toString() ?? '';
  if (value.isNotEmpty) return value;
  return booking['total_amount']?.toString() ?? '0';
}

String _venueNameForCard(
  Map<String, dynamic> booking,
  Map<String, dynamic> venue,
) {
  final name = booking['venueName']?.toString() ?? '';
  if (name.isNotEmpty) return name;
  final fromVenue = venue['name']?.toString() ?? '';
  if (fromVenue.isNotEmpty) return fromVenue;
  return '-';
}

String _courtNameForCard(
  Map<String, dynamic> booking,
  Map<String, dynamic> court,
) {
  final name = booking['courtName']?.toString() ?? '';
  if (name.isNotEmpty) return name;
  final fromCourt = court['name']?.toString() ?? '';
  if (fromCourt.isNotEmpty) return fromCourt;
  return '-';
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
        Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: AppFontWeights.semiBold, color: AppColors.txtPrimary)),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtDisabled)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
