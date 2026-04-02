import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import 'widgets/match_list_card.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  int _tabIndex = 0;
  String _activeSkill = 'All';

  final List<String> _tabLabels = ['Tonight', 'Tomorrow', 'Weekend', 'Open Matches'];

  List<Map<String, dynamic>> get _filteredMatches {
    return MockData.matches.where((match) {
      if (_activeSkill == 'All') return true;
      if (_activeSkill == 'Friends') return (match['friendsIn'] ?? 0) > 0;
      return match['skillLevel'] == _activeSkill;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Discover', style: AppText.h2),
        elevation: 0,
        backgroundColor: AppColors.bgPrimary,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                final bool isSelected = _tabIndex == i;

                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: AppSpacing.xs2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm2,
                      vertical: AppSpacing.xs3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.green : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: !isSelected
                          ? Border.all(color: AppColors.borderClr.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.bgPrimary : AppColors.txtDisabled,
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
              options: const ['All', 'Beginner', 'Intermediate', 'Advanced', 'Friends'],
              selected: _activeSkill,
              onSelected: (v) => setState(() => _activeSkill = v),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // MATCH LIST
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: matches.isEmpty
                  ? EmptyState(
                      key: ValueKey('empty_$_tabIndex$_activeSkill'),
                      icon: Icons.explore_off,
                      title: 'No matches ${_tabLabels[_tabIndex]}',
                      subtitle: 'Check back later or explore open matches',
                    )
                  : ListView.separated(
                      key: ValueKey('list_$_tabIndex$_activeSkill'),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.sm2,
                        AppSpacing.xxs,
                        AppSpacing.sm2,
                        MediaQuery.of(context).padding.bottom + kNavBarHeight + 20,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) => MatchListCard(match: matches[i], index: i),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
