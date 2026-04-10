import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/player_venues_service.dart';

class VenueDiscoveryState {
  const VenueDiscoveryState({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.isLoadingMore,
    this.error,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int limit;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  factory VenueDiscoveryState.initial() {
    return const VenueDiscoveryState(
      items: <Map<String, dynamic>>[],
      page: 1,
      limit: 20,
      hasMore: true,
      isLoadingMore: false,
      error: null,
    );
  }

  VenueDiscoveryState copyWith({
    List<Map<String, dynamic>>? items,
    int? page,
    int? limit,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return VenueDiscoveryState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final playerVenuesServiceProvider = Provider<PlayerVenuesService>((ref) {
  return PlayerVenuesService.instance;
});

final venueDiscoveryControllerProvider =
    AsyncNotifierProvider<VenueDiscoveryController, VenueDiscoveryState>(
  VenueDiscoveryController.new,
);

class VenueDiscoveryController extends AsyncNotifier<VenueDiscoveryState> {
  late final PlayerVenuesService _service =
      ref.read(playerVenuesServiceProvider);

  String _query = '';

  @override
  Future<VenueDiscoveryState> build() async {
    final result =
        await _service.browseVenuesPage(query: _query, page: 1, limit: 20);
    return VenueDiscoveryState(
      items: result.items,
      page: result.page,
      limit: result.limit,
      hasMore: result.hasMore,
      isLoadingMore: false,
      error: null,
    );
  }

  Future<void> search(String query) async {
    _query = query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _service.browseVenuesPage(
        query: _query,
        page: 1,
        limit: 20,
      );
      return VenueDiscoveryState(
        items: result.items,
        page: result.page,
        limit: result.limit,
        hasMore: result.hasMore,
        isLoadingMore: false,
        error: null,
      );
    });
  }

  Future<void> refresh() => search(_query);

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = current.page + 1;
      final result = await _service.browseVenuesPage(
        query: _query,
        page: nextPage,
        limit: current.limit,
      );

      final merged = <Map<String, dynamic>>[
        ...current.items,
        ...result.items,
      ];

      state = AsyncData(
        current.copyWith(
          items: merged,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on VenueApiException catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          error: error.message,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          error: 'Unable to load more venues right now.',
        ),
      );
    }
  }
}
