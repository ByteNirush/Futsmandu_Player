import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import '../matches/data/models/player_match_models.dart';
import '../matches/presentation/providers/matches_controller.dart';
import 'widgets/match_list_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  static const List<MatchDiscoveryTab> _tabs = <MatchDiscoveryTab>[
    MatchDiscoveryTab.tonight,
    MatchDiscoveryTab.tomorrow,
    MatchDiscoveryTab.weekend,
    MatchDiscoveryTab.open,
  ];

  static const List<String> _tabLabels = [
    'Tonight',
    'Tomorrow',
    'Weekend',
    'Open Matches',
  ];

  static const List<MatchDiscoveryTab> _searchDropdownTabs =
      <MatchDiscoveryTab>[
    MatchDiscoveryTab.tonight,
    MatchDiscoveryTab.tomorrow,
    MatchDiscoveryTab.weekend,
  ];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(matchDiscoveryControllerProvider.notifier).setTab(_tabs.first);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MatchSummary> _filteredMatches(MatchDiscoveryState state) {
    final query = _searchQuery.toLowerCase();
    return state.activeItems.where((match) {
      if (query.isEmpty) {
        return true;
      }

      return match.venueName.toLowerCase().contains(query) ||
          match.courtName.toLowerCase().contains(query) ||
          match.venueAddress.toLowerCase().contains(query);
    }).toList();
  }

  String _labelForTab(MatchDiscoveryTab tab) {
    final index = _tabs.indexOf(tab);
    if (index < 0) {
      return _tabLabels.first;
    }
    return _tabLabels[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncState = ref.watch(matchDiscoveryControllerProvider);
    final state = asyncState.valueOrNull ?? MatchDiscoveryState.initial();
    final tabIndex = _tabs.indexOf(state.activeTab);
    final safeTabIndex = tabIndex < 0 ? 0 : tabIndex;
    final selectedDropdownTab = _searchDropdownTabs.contains(state.activeTab)
        ? state.activeTab
        : _searchDropdownTabs.first;
    final matches = _filteredMatches(state);
    final isLoading = asyncState.isLoading || state.isRefreshing;
    final error =
        asyncState.whenOrNull(error: (error, _) => error.toString()) ??
            state.activeError;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: AppTypography.subHeading(context, scheme).copyWith(color: scheme.onSurface),
        ),
        elevation: 0,
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(matchDiscoveryControllerProvider.notifier)
                  .refreshActiveTab();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          if (error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTypography.body(context, scheme).copyWith(
                        fontSize: 14 * AppTypographyScale.fromContext(context),
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: 'Search venues...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: scheme.onSurfaceVariant,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          FocusScope.of(context).unfocus();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: scheme.onSurfaceVariant,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${matches.length} ${matches.length == 1 ? 'match' : 'matches'} found',
                    style: AppTypography.body(context, scheme).copyWith(
                      fontSize: 13 * AppTypographyScale.fromContext(context),
                      fontWeight: AppFontWeights.medium,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MatchDiscoveryTab>(
                        value: selectedDropdownTab,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: scheme.primary,
                          size: 18,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        dropdownColor: scheme.surfaceContainerHigh,
                        onChanged: (value) {
                          if (value == null) return;
                          ref
                              .read(matchDiscoveryControllerProvider.notifier)
                              .setTab(value);
                        },
                        items: _searchDropdownTabs.map((tab) {
                          return DropdownMenuItem<MatchDiscoveryTab>(
                            value: tab,
                            child: Text(
                              _labelForTab(tab),
                              style: AppTypography.textTheme(scheme).labelMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: AppFontWeights.semiBold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // MATCH LIST
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: matches.isEmpty
                  ? EmptyStateWidget(
                      key: ValueKey(
                        'empty_$safeTabIndex$_searchQuery',
                      ),
                      type: EmptyStateType.noSearchResults,
                    )
                  : ListView.separated(
                      key: ValueKey(
                        'list_$safeTabIndex$_searchQuery',
                      ),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        MediaQuery.of(context).padding.bottom +
                            kNavBarHeight +
                            20,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (ctx, i) =>
                          MatchListCard(match: matches[i], index: i),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
