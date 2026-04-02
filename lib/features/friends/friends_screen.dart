import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/futs_card.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _tab = 0;
  String _search = '';
  final Set<String> _sent = {};

  // Safely mapping from MockData due to missing property likelihoods
  late List<Map<String, dynamic>> _allFriends;
  late List<Map<String, dynamic>> _friendRequests;
  late List<Map<String, dynamic>> _searchPlayers;

  final String _playerFilter = 'All';

  @override
  void initState() {
    super.initState();
    try {
      _allFriends = List<Map<String, dynamic>>.from(MockData.friends);
    } catch (_) { _allFriends = []; }
    try {
      // MockData fallback via dynamic properties lookup
      _friendRequests = List<Map<String, dynamic>>.from((MockData as dynamic).friendRequests);
    } catch (_) { _friendRequests = _allFriends.take(1).toList(); }
    try {
      _searchPlayers = List<Map<String, dynamic>>.from((MockData as dynamic).searchPlayers);
    } catch (_) { _searchPlayers = _allFriends.skip(1).take(2).toList(); }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabLabels = [
      'Friends (${_allFriends.length})',
      'Requests (${_friendRequests.length})',
      'Find Players'
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Friends', style: AppText.h2),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ROW TAB SELECTOR
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderClr)),
            ),
            child: Row(
              children: tabLabels.asMap().entries.map((e) {
                final int i = e.key;
                final String label = e.value;
                final bool isSelected = _tab == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _tab = i;
                      _search = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
                      color: AppColors.bgPrimary.withValues(alpha: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: AppText.h3.copyWith(
                              fontSize: 14,
                              color: isSelected ? AppColors.green : AppColors.txtDisabled,
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.green
                                  : AppColors.green.withValues(alpha: 0),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                // TAB 0 — Friends
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs2),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: AppText.body.copyWith(color: AppColors.txtPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search friends…',
                          prefixIcon: Icon(Icons.search, color: AppColors.txtDisabled),
                          hintStyle: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
                          filled: true,
                          fillColor: AppColors.bgElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.green, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + kNavBarHeight + 12,
                        ),
                        children: _allFriends
                            .where((f) => (f['name'] as String).toLowerCase().contains(_search.toLowerCase()))
                            .map((f) => _FriendTile(f: f))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                // TAB 1 — Requests
                ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + kNavBarHeight + 12,
                  ),
                  itemCount: _friendRequests.length,
                  itemBuilder: (context, index) {
                    final r = _friendRequests[index];
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: FutsCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs2,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.bgElevated,
                              backgroundImage: NetworkImage(r['avatarUrl'] ?? ''),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'] ?? '', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${r['mutualFriends'] ?? 0} mutual friend${(r['mutualFriends'] ?? 0) != 1 ? 's' : ''}',
                                    style: AppText.bodySm,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check_circle_rounded, size: 28, color: AppColors.green),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${r['name']} accepted')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel_rounded, size: 28, color: AppColors.red),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request declined')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // TAB 2 — Find Players
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs2),
                      child: TextField(
                        style: AppText.body.copyWith(color: AppColors.txtPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone…',
                          prefixIcon: Icon(Icons.search, color: AppColors.txtDisabled),
                          hintStyle: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
                          filled: true,
                          fillColor: AppColors.bgElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.green, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.xs2,
                              right: AppSpacing.xs2,
                              bottom: AppSpacing.xs,
                            ),
                      child: FilterChipRow(
                        options: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
                        selected: _playerFilter,
                        onSelected: (_) {}, // Simplified scaffold UI binding
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + kNavBarHeight + 12,
                        ),
                        itemCount: _searchPlayers.length,
                        itemBuilder: (context, index) {
                          final p = _searchPlayers[index];
                          final bool isSent = _sent.contains(p['id']);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.bgElevated,
                                  backgroundImage: NetworkImage(p['avatarUrl'] ?? ''),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'] ?? '', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          _SkillBadge(skill: p['skillLevel'] ?? 'Intermediate'),
                                          const SizedBox(width: 8),
                                          Text('${p['matchesPlayed'] ?? 0} matches', style: AppText.label),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _sent.add(p['id'])),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSent
                                          ? AppColors.bgElevated
                                          : AppColors.bgElevated.withValues(alpha: 0),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isSent ? AppColors.borderClr : AppColors.green,
                                      ),
                                    ),
                                    child: Text(
                                      isSent ? 'Requested' : 'Add Friend',
                                      style: GoogleFonts.barlow(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSent ? AppColors.txtDisabled : AppColors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Map<String, dynamic> f;

  const _FriendTile({required this.f});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: NetworkImage(f['avatarUrl'] ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['name'], style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _SkillBadge(skill: f['skillLevel'] ?? 'Intermediate'),
                    const SizedBox(width: 8),
                    Text('${f['matchesPlayed'] ?? 0} matches', style: AppText.label),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.reliabilityColor(f['reliabilityScore'] as int? ?? 70),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invite sent to ${f['name']}')),
                  );
                },
                child: Text('Invite', style: AppText.label.copyWith(color: AppColors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String skill;

  const _SkillBadge({required this.skill});

  Color _skillColor(String s) {
    if (s == 'Advanced') return AppColors.red;
    if (s == 'Intermediate') return AppColors.amber;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final c = _skillColor(skill);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        skill,
        style: GoogleFonts.barlow(
          fontSize: 10,
          color: c,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
