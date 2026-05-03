import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../shared/widgets/enhanced_empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import 'data/models/booking_models.dart';
import 'presentation/providers/booking_controllers.dart';
import 'presentation/widgets/booking_detail_sheet.dart';
import 'presentation/widgets/booking_history_card.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _contentHorizontalPadding = AppSpacing.xxs;

  static const List<String> _filters = <String>[
    'All',
    'Confirmed',
    'Completed',
    'Cancelled',
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

  void _showBookingDetail(BookingHistoryItem booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return BookingDetailSheet(
          bookingId: booking.id,
          bookingItem: booking,
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
        title: Text(
          'My Bookings',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: AppFontWeights.bold),
        ),
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
              Text(
                stateAsync.error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => ref
                    .read(bookingHistoryControllerProvider.notifier)
                    .refresh(),
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

        return BookingHistoryCard(
          booking: booking,
          onTap: () => _showBookingDetail(booking),
        );
      },
    );
  }
}
