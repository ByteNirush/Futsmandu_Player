import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
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
                  Text('Cancel Booking?', style: AppText.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(booking.venueName, style: AppText.bodySm),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    style: AppText.body.copyWith(color: AppColors.txtPrimary),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Let the venue know why you are cancelling...',
                      alignLabelWithHint: true,
                      labelStyle: AppText.label,
                      hintStyle:
                          AppText.bodySm.copyWith(color: AppColors.txtDisabled),
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
                        style: AppText.bodySm, textAlign: TextAlign.center),
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
                    Text('Booking Detail', style: AppText.h2),
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
        title: Text('My Bookings', style: AppText.h2),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs3),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(stateAsync.error.toString(),
                    style: AppText.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => ref
                      .read(bookingHistoryControllerProvider.notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final state = stateAsync.value ?? BookingHistoryState.initial();

    if (state.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'No bookings',
            subtitle: 'Your booking history will appear here',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
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
        return _BookingCard(
          booking: booking.toMap(),
          onTap: () => _showBookingDetail(booking.id),
          onCancel: booking.status == 'CONFIRMED'
              ? () => _showCancelSheet(booking)
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
  });

  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

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
                        style: AppText.h3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(booking['courtName']?.toString() ?? '-',
                          style: AppText.bodySm),
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
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: AppTextStyles.semiBold,
                    color: AppColors.txtPrimary,
                  ),
                ),
                const Spacer(),
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
        Text(text, style: AppText.label.copyWith(color: AppColors.txtPrimary)),
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
                style: AppText.bodySm.copyWith(color: AppColors.txtDisabled)),
          ),
          Expanded(child: Text(value, style: AppText.bodySm)),
        ],
      ),
    );
  }
}
