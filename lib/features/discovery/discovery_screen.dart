import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
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

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(matchDiscoveryControllerProvider.notifier).setTab(_tabs.first);
    });
  }

  List<MatchSummary> _filteredMatches(MatchDiscoveryState state) {
    return state.activeItems.where((match) {
      if (state.activeSkill == 'All') return true;
      if (state.activeSkill == 'Friends') return match.friendsIn > 0;
      return match.skillLevel == state.activeSkill;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(matchDiscoveryControllerProvider);
    final state = asyncState.valueOrNull ?? MatchDiscoveryState.initial();
    final tabIndex = _tabs.indexOf(state.activeTab);
    final safeTabIndex = tabIndex < 0 ? 0 : tabIndex;
    final matches = _filteredMatches(state);
    final isLoading = asyncState.isLoading || state.isRefreshing;
    final error =
        asyncState.whenOrNull(error: (error, _) => error.toString()) ??
            state.activeError;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Discover', style: AppText.h2),
        elevation: 0,
        backgroundColor: AppColors.bgPrimary,
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
                AppSpacing.sm2,
                AppSpacing.xs,
                AppSpacing.sm2,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                error,
                style: AppText.bodySm.copyWith(color: AppColors.red),
              ),
            ),
          // TAB STRIP
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm2,
              vertical: AppSpacing.xs2,
            ),
            child: Row(
              children: _tabLabels.asMap().entries.map((entry) {
                final int i = entry.key;
                final String label = entry.value;
                final bool isSelected = safeTabIndex == i;

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(matchDiscoveryControllerProvider.notifier)
                        .setTab(_tabs[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: AppSpacing.xs2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm2,
                      vertical: AppSpacing.xs3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.green : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: !isSelected
                          ? Border.all(
                              color: AppColors.borderClr.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.bgPrimary
                            : AppColors.txtDisabled,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // SKILL FILTER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: FilterChipRow(
              options: const [
                'All',
                'Beginner',
                'Intermediate',
                'Advanced',
                'Friends'
              ],
              selected: state.activeSkill,
              onSelected: (v) {
                ref.read(matchDiscoveryControllerProvider.notifier).setSkill(v);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2),
            child: Row(
              children: [
                Text(
                  '${matches.length} matches',
                  style: AppText.bodySm.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  _tabLabels[safeTabIndex],
                  style: AppText.label,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // MATCH LIST
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: matches.isEmpty
                  ? EmptyState(
                      key: ValueKey('empty_$safeTabIndex${state.activeSkill}'),
                      icon: Icons.explore_off,
                      title: 'No matches ${_tabLabels[safeTabIndex]}',
                      subtitle: 'Check back later or explore open matches',
                    )
                  : ListView.separated(
                      key: ValueKey('list_$safeTabIndex${state.activeSkill}'),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.sm2,
                        AppSpacing.xxs,
                        AppSpacing.sm2,
                        MediaQuery.of(context).padding.bottom +
                            kNavBarHeight +
                            20,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
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
