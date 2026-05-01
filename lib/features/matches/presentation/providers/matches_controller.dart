import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_match_models.dart';
import '../../data/services/player_match_service.dart';

enum MatchDiscoveryTab {
  tonight,
  tomorrow,
  weekend,
  open,
}

class MatchDiscoveryState {
  const MatchDiscoveryState({
    required this.activeTab,
    required this.activeSkill,
    required this.itemsByTab,
    required this.errorByTab,
    required this.isRefreshing,
  });

  final MatchDiscoveryTab activeTab;
  final String activeSkill;
  final Map<MatchDiscoveryTab, List<MatchSummary>> itemsByTab;
  final Map<MatchDiscoveryTab, String?> errorByTab;
  final bool isRefreshing;

  factory MatchDiscoveryState.initial() {
    return const MatchDiscoveryState(
      activeTab: MatchDiscoveryTab.tonight,
      activeSkill: 'All',
      itemsByTab: <MatchDiscoveryTab, List<MatchSummary>>{},
      errorByTab: <MatchDiscoveryTab, String?>{},
      isRefreshing: false,
    );
  }

  MatchDiscoveryState copyWith({
    MatchDiscoveryTab? activeTab,
    String? activeSkill,
    Map<MatchDiscoveryTab, List<MatchSummary>>? itemsByTab,
    Map<MatchDiscoveryTab, String?>? errorByTab,
    bool? isRefreshing,
  }) {
    return MatchDiscoveryState(
      activeTab: activeTab ?? this.activeTab,
      activeSkill: activeSkill ?? this.activeSkill,
      itemsByTab: itemsByTab ?? this.itemsByTab,
      errorByTab: errorByTab ?? this.errorByTab,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  List<MatchSummary> get activeItems {
    return itemsByTab[activeTab] ?? const <MatchSummary>[];
  }

  String? get activeError {
    return errorByTab[activeTab];
  }
}

final matchServiceProvider = Provider<PlayerMatchService>((ref) {
  return PlayerMatchService.instance;
});

final matchDiscoveryControllerProvider =
    AsyncNotifierProvider<MatchDiscoveryController, MatchDiscoveryState>(
  MatchDiscoveryController.new,
);

final matchDetailProvider =
    FutureProvider.family<MatchDetail, String>((ref, matchId) async {
  final service = ref.read(matchServiceProvider);
  return service.fetchMatch(matchId);
});

final invitePreviewProvider =
    FutureProvider.family<MatchInvitePreview, String>((ref, token) async {
  final service = ref.read(matchServiceProvider);
  return service.fetchInvitePreview(token);
});

class MatchDiscoveryController extends AsyncNotifier<MatchDiscoveryState> {
  static const double fallbackLatitude = 27.7172;
  static const double fallbackLongitude = 85.3240;

  PlayerMatchService get _service => ref.read(matchServiceProvider);

  @override
  Future<MatchDiscoveryState> build() async {
    final initial = MatchDiscoveryState.initial();
    final items = await _loadTab(initial.activeTab);

    return initial.copyWith(
      itemsByTab: {
        initial.activeTab: items,
      },
      errorByTab: {
        initial.activeTab: null,
      },
    );
  }

  Future<void> setTab(MatchDiscoveryTab tab) async {
    final current = state.valueOrNull ?? MatchDiscoveryState.initial();

    if (current.activeTab == tab) {
      return;
    }

    state = AsyncData(current.copyWith(activeTab: tab));

    final updated = state.valueOrNull;
    if (updated == null || updated.itemsByTab.containsKey(tab)) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _loadTab(tab);
      return updated.copyWith(
        itemsByTab: {
          ...updated.itemsByTab,
          tab: items,
        },
        errorByTab: {
          ...updated.errorByTab,
          tab: null,
        },
      );
    });
  }

  void setSkill(String skill) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(activeSkill: skill));
  }

  Future<void> refreshActiveTab() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isRefreshing: true));

    try {
      final items = await _loadTab(current.activeTab);
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          isRefreshing: false,
          itemsByTab: {
            ...latest.itemsByTab,
            current.activeTab: items,
          },
          errorByTab: {
            ...latest.errorByTab,
            current.activeTab: null,
          },
        ),
      );
    } catch (error) {
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          isRefreshing: false,
          errorByTab: {
            ...latest.errorByTab,
            current.activeTab: error.toString(),
          },
        ),
      );
    }
  }

  Future<List<MatchSummary>> _loadTab(MatchDiscoveryTab tab) async {
    switch (tab) {
      case MatchDiscoveryTab.tonight:
        // Fetch both open matches for today AND tonight matches (same as home screen)
        final today = DateTime.now().toIso8601String().split('T').first;
        final openMatches = await _service.fetchOpenMatches(
          date: today,
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
        );
        final tonightMatches = await _service.fetchTonightMatches(
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
        );
        // Merge and deduplicate by ID (prioritize open matches)
        final mergedById = <String, MatchSummary>{};
        for (final match in [...openMatches, ...tonightMatches]) {
          final id = match.matchGroupId.isNotEmpty ? match.matchGroupId : match.id;
          if (id.isNotEmpty && !mergedById.containsKey(id)) {
            mergedById[id] = match;
          }
        }
        return mergedById.values.toList();
      case MatchDiscoveryTab.tomorrow:
        return _service.fetchTomorrowMatches(
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
        );
      case MatchDiscoveryTab.weekend:
        return _service.fetchWeekendMatches(
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
        );
      case MatchDiscoveryTab.open:
        return _service.fetchOpenMatches(
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
        );
    }
  }
}
