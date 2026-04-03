import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/futs_card.dart';
import 'data/services/player_friends_service.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final PlayerFriendsService _friendsService = PlayerFriendsService.instance;

  int _tab = 0;
  String _friendSearch = '';
  final Set<String> _sent = {};
  bool _isLoading = false;
  bool _isSearchingPlayers = false;
  String? _error;
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _allFriends = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _friendRequests = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _searchPlayers = const <Map<String, dynamic>>[];

  final String _playerFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadFriendsData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFriendsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait(<Future<List<Map<String, dynamic>>>>[
        _friendsService.getFriends(),
        _friendsService.getFriendRequests(),
      ]);

      if (!mounted) return;
      setState(() {
        _allFriends = results[0];
        _friendRequests = results[1];
      });
    } on FriendsApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load friends data');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSearchPlayers({required String query}) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchPlayers = const <Map<String, dynamic>>[];
        _isSearchingPlayers = false;
      });
      return;
    }

    setState(() {
      _isSearchingPlayers = true;
      _error = null;
    });

    try {
      final players = await _friendsService.searchPlayers(query: query.trim());
      if (!mounted) return;
      setState(() {
        _searchPlayers = players;
      });
    } on FriendsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchPlayers = const <Map<String, dynamic>>[];
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchPlayers = const <Map<String, dynamic>>[];
        _error = 'Failed to search players';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isSearchingPlayers = false);
    }
  }

  void _onSearchPlayersChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadSearchPlayers(query: value);
    });
  }

  Future<void> _sendFriendRequest(Map<String, dynamic> player) async {
    final recipientId = (player['id'] ?? '').toString();
    if (recipientId.isEmpty) return;

    try {
      await _friendsService.sendFriendRequest(recipientId: recipientId);
      if (!mounted) return;

      setState(() {
        _sent.add(recipientId);
      });

      _showMessage('Friend request sent to ${player['name'] ?? 'player'}');
    } on FriendsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to send friend request');
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    final friendshipId = (request['friendshipId'] ?? '').toString();
    if (friendshipId.isEmpty) return;

    try {
      await _friendsService.acceptFriendRequest(friendshipId: friendshipId);
      if (!mounted) return;

      await _loadFriendsData();
      _showMessage('${request['name'] ?? 'Request'} accepted');
    } on FriendsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to accept request');
    }
  }

  Future<void> _declineOrRemoveFriendship({
    required String friendshipId,
    required String successMessage,
  }) async {
    if (friendshipId.isEmpty) return;

    try {
      await _friendsService.removeFriendship(friendshipId: friendshipId);
      if (!mounted) return;

      await _loadFriendsData();
      _showMessage(successMessage);
    } on FriendsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Action failed. Please try again');
    }
  }

  Future<void> _blockPlayer({required String playerId}) async {
    if (playerId.isEmpty) return;

    try {
      await _friendsService.blockPlayer(playerId: playerId);
      if (!mounted) return;

      await _loadFriendsData();
      _showMessage('User blocked');
    } on FriendsApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Failed to block user');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriendsData,
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
                AppSpacing.xs2,
                AppSpacing.xs,
                AppSpacing.xs2,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                _error!,
                style: AppText.bodySm.copyWith(color: AppColors.red),
              ),
            ),
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
                      _friendSearch = '';
                    }),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
                      color: AppColors.bgPrimary.withValues(alpha: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: AppText.h3.copyWith(
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.green
                                  : AppColors.txtDisabled,
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
                        onChanged: (v) => setState(() => _friendSearch = v),
                        style:
                            AppText.body.copyWith(color: AppColors.txtPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search friends…',
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.txtDisabled),
                          hintStyle: AppText.bodySm
                              .copyWith(color: AppColors.txtDisabled),
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
                            borderSide:
                                BorderSide(color: AppColors.green, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom +
                              kNavBarHeight +
                              12,
                        ),
                        children: _allFriends
                            .where((f) => (f['name'] as String)
                                .toLowerCase()
                                .contains(_friendSearch.toLowerCase()))
                            .map(
                              (f) => _FriendTile(
                                f: f,
                                onRemove: () => _declineOrRemoveFriendship(
                                  friendshipId:
                                      (f['friendshipId'] ?? '').toString(),
                                  successMessage:
                                      '${f['name'] ?? 'Friend'} removed',
                                ),
                                onBlock: () => _blockPlayer(
                                  playerId: (f['id'] ?? '').toString(),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                // TAB 1 — Requests
                ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        kNavBarHeight +
                        12,
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
                              backgroundImage: _avatarProvider(r['avatarUrl']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'] ?? '',
                                      style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w600)),
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
                                  icon: Icon(Icons.check_circle_rounded,
                                      size: 28, color: AppColors.green),
                                  onPressed: () => _acceptRequest(r),
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel_rounded,
                                      size: 28, color: AppColors.red),
                                  onPressed: () => _declineOrRemoveFriendship(
                                    friendshipId:
                                        (r['friendshipId'] ?? '').toString(),
                                    successMessage: 'Request declined',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.block_rounded,
                                      size: 24, color: AppColors.txtDisabled),
                                  onPressed: () => _blockPlayer(
                                    playerId: (r['id'] ?? '').toString(),
                                  ),
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
                        onChanged: _onSearchPlayersChanged,
                        style:
                            AppText.body.copyWith(color: AppColors.txtPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone…',
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.txtDisabled),
                          hintStyle: AppText.bodySm
                              .copyWith(color: AppColors.txtDisabled),
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
                            borderSide:
                                BorderSide(color: AppColors.green, width: 1.5),
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
                        options: const [
                          'All',
                          'Beginner',
                          'Intermediate',
                          'Advanced'
                        ],
                        selected: _playerFilter,
                        onSelected: (_) {}, // Simplified scaffold UI binding
                      ),
                    ),
                    Expanded(
                      child: _isSearchingPlayers
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom +
                                    kNavBarHeight +
                                    12,
                              ),
                              itemCount: _searchPlayers.length,
                              itemBuilder: (context, index) {
                                final p = _searchPlayers[index];
                                final String playerId =
                                    (p['id'] ?? '').toString();
                                final bool isSent = _sent.contains(playerId);

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
                                        backgroundImage:
                                            _avatarProvider(p['avatarUrl']),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'] ?? '',
                                              style: AppText.body.copyWith(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                _SkillBadge(
                                                    skill: p['skillLevel'] ??
                                                        'Intermediate'),
                                                const SizedBox(width: 8),
                                                Text(
                                                    '${p['matchesPlayed'] ?? 0} matches',
                                                    style: AppText.label),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: isSent
                                            ? null
                                            : () => _sendFriendRequest(p),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSent
                                                ? AppColors.bgElevated
                                                : AppColors.bgElevated
                                                    .withValues(alpha: 0),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: isSent
                                                  ? AppColors.borderClr
                                                  : AppColors.green,
                                            ),
                                          ),
                                          child: Text(
                                            isSent ? 'Requested' : 'Add Friend',
                                            style: GoogleFonts.barlow(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isSent
                                                  ? AppColors.txtDisabled
                                                  : AppColors.green,
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

  ImageProvider<Object>? _avatarProvider(dynamic value) {
    final url = value is String ? value.trim() : '';
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }
}

class _FriendTile extends StatelessWidget {
  final Map<String, dynamic> f;
  final VoidCallback onRemove;
  final VoidCallback onBlock;

  const _FriendTile({
    required this.f,
    required this.onRemove,
    required this.onBlock,
  });

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
            backgroundImage: _avatarProvider(f['avatarUrl']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['name'],
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _SkillBadge(skill: f['skillLevel'] ?? 'Intermediate'),
                    const SizedBox(width: 8),
                    Text('${f['matchesPlayed'] ?? 0} matches',
                        style: AppText.label),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: AppColors.txtDisabled, size: 20),
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  } else if (value == 'block') {
                    onBlock();
                  }
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: Text('Remove Friend'),
                  ),
                  PopupMenuItem<String>(
                    value: 'block',
                    child: Text('Block User'),
                  ),
                ],
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.reliabilityColor(
                      f['reliabilityScore'] as int? ?? 70),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invite sent to ${f['name']}')),
                  );
                },
                child: Text('Invite',
                    style: AppText.label.copyWith(color: AppColors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _avatarProvider(dynamic value) {
    final url = value is String ? value.trim() : '';
    if (url.isEmpty) return null;
    return NetworkImage(url);
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
