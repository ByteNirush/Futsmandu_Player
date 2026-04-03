import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import '../matches/data/services/player_match_service.dart';
import 'widgets/match_list_card.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const double _fallbackLatitude = 27.7172;
  static const double _fallbackLongitude = 85.3240;

  final PlayerMatchService _matchService = PlayerMatchService.instance;

  int _tabIndex = 0;
  String _activeSkill = 'All';
  bool _isLoading = false;
  String? _error;
  final Map<int, List<Map<String, dynamic>>> _tabMatches =
      <int, List<Map<String, dynamic>>>{};

  static const List<String> _tabLabels = [
    'Tonight',
    'Tomorrow',
    'Weekend',
    'Open Matches',
  ];

  @override
  void initState() {
    super.initState();
    _loadTabMatches(_tabIndex);
  }

  bool _isEveningMatch(Map<String, dynamic> match) {
    final time = (match['time'] ?? '').toString();
    final hour = int.tryParse(time.split(':').first) ?? 0;
    return hour >= 17;
  }

  bool _passesTab(Map<String, dynamic> match) {
    switch (_tabIndex) {
      case 0:
        return _isEveningMatch(match);
      case 1:
        return !_isEveningMatch(match);
      case 2:
        final date = (match['date'] ?? '').toString();
        return date.startsWith('Sat') || date.startsWith('Sun');
      case 3:
        return match['isOpen'] == true;
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> get _filteredMatches {
    final currentTabMatches =
        _tabMatches[_tabIndex] ?? const <Map<String, dynamic>>[];
    return currentTabMatches.where((match) {
      if (!_passesTab(match)) return false;
      if (_activeSkill == 'All') return true;
      if (_activeSkill == 'Friends') return (match['friendsIn'] ?? 0) > 0;
      return match['skillLevel'] == _activeSkill;
    }).toList();
  }

  Future<void> _loadTabMatches(int tabIndex, {bool forceReload = false}) async {
    if (!forceReload && _tabMatches.containsKey(tabIndex)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      late final List<Map<String, dynamic>> matches;
      switch (tabIndex) {
        case 0:
          matches = await _matchService.getTonightMatches(
            latitude: _fallbackLatitude,
            longitude: _fallbackLongitude,
          );
          break;
        case 1:
          matches = await _matchService.getTomorrowMatches(
            latitude: _fallbackLatitude,
            longitude: _fallbackLongitude,
          );
          break;
        case 2:
          matches = await _matchService.getWeekendMatches(
            latitude: _fallbackLatitude,
            longitude: _fallbackLongitude,
          );
          break;
        case 3:
          matches = await _matchService.getOpenMatches(
            latitude: _fallbackLatitude,
            longitude: _fallbackLongitude,
          );
          break;
        default:
          matches = const <Map<String, dynamic>>[];
      }

      if (!mounted) return;
      setState(() {
        _tabMatches[tabIndex] = matches;
      });
    } on MatchApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _tabMatches[tabIndex] = const <Map<String, dynamic>>[];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load matches right now';
        _tabMatches[tabIndex] = const <Map<String, dynamic>>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTabMatches(_tabIndex, forceReload: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
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
                _error!,
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
                final bool isSelected = _tabIndex == i;

                return GestureDetector(
                  onTap: () {
                    setState(() => _tabIndex = i);
                    _loadTabMatches(i);
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
                      style: GoogleFonts.barlow(
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
              selected: _activeSkill,
              onSelected: (v) => setState(() => _activeSkill = v),
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
                  _tabLabels[_tabIndex],
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
