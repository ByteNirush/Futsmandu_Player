import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/booking_models.dart';
import 'booking_repository_provider.dart';

class BookingHistoryState {
  const BookingHistoryState({
    required this.items,
    required this.filter,
    required this.page,
    required this.nextCursor,
    required this.isLoadingMore,
    this.error,
  });

  final List<BookingHistoryItem> items;
  final String filter;
  final int page;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? error;

  factory BookingHistoryState.initial() {
    return const BookingHistoryState(
      items: <BookingHistoryItem>[],
      filter: 'All',
      page: 1,
      nextCursor: null,
      isLoadingMore: false,
      error: null,
    );
  }

  BookingHistoryState copyWith({
    List<BookingHistoryItem>? items,
    String? filter,
    int? page,
    String? nextCursor,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return BookingHistoryState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingHistoryControllerProvider =
    AsyncNotifierProvider<BookingHistoryController, BookingHistoryState>(
  BookingHistoryController.new,
);

final bookingDetailProvider =
    FutureProvider.family<BookingDetail, String>((ref, bookingId) async {
  final repository = ref.read(bookingRepositoryProvider);
  return repository.getBookingDetail(bookingId);
});

class BookingHistoryController extends AsyncNotifier<BookingHistoryState> {
  @override
  Future<BookingHistoryState> build() async {
    final repository = ref.read(bookingRepositoryProvider);
    final result = await repository.getBookings(page: 1);

    return BookingHistoryState(
      items: result.items,
      filter: 'All',
      page: 2,
      nextCursor: result.nextCursor,
      isLoadingMore: false,
      error: null,
    );
  }

  Future<void> setFilter(String filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingRepositoryProvider);
      final result = await repository.getBookings(
        status: _backendStatusFilter(filter),
        page: 1,
      );

      return BookingHistoryState(
        items: result.items,
        filter: filter,
        page: 2,
        nextCursor: result.nextCursor,
        isLoadingMore: false,
        error: null,
      );
    });
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filter = current?.filter ?? 'All';
    await setFilter(filter);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final result = await repository.getBookings(
        status: _backendStatusFilter(current.filter),
        page: current.page,
        cursor: current.nextCursor,
      );

      state = AsyncData(
        current.copyWith(
          items: <BookingHistoryItem>[...current.items, ...result.items],
          page: current.page + 1,
          nextCursor: result.nextCursor,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<BookingCancellationResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final repository = ref.read(bookingRepositoryProvider);
    final result = await repository.cancelBooking(
      bookingId: bookingId,
      reason: reason,
    );

    final current = state.valueOrNull;
    if (current != null) {
      final updated = current.items.map((item) {
        if (item.id != bookingId) return item;
        return BookingHistoryItem.fromMap({
          ...item.toMap(),
          'status': 'CANCELLED',
          'refundAmount': result.refundAmount,
        });
      }).toList(growable: false);

      state = AsyncData(current.copyWith(items: updated));
    }

    return result;
  }

  String? _backendStatusFilter(String uiFilter) {
    switch (uiFilter) {
      case 'Confirmed':
        return 'CONFIRMED';
      case 'Completed':
        return 'COMPLETED';
      case 'Cancelled':
        return 'CANCELLED';
      case 'Held':
        return 'HELD';
      default:
        return null;
    }
  }
}
