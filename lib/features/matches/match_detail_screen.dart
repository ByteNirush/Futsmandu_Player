import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/painters/field_painter.dart';
import '../../core/services/player_auth_storage_service.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/services/player_match_service.dart';
import '../friends/data/services/player_friends_service.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final PlayerMatchService _matchService = PlayerMatchService.instance;
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _currentUserId;
  Map<String, dynamic>? _match;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadMatch();
  }

  Future<void> _loadMatch({bool refresh = false}) async {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final matchId = _matchIdFromArgs(args);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isRefreshing = refresh;
      _errorMessage = null;
    });

    try {
      _currentUserId = (await _authStorage.getUser())?['id']?.toString();

      if (matchId != null && matchId.isNotEmpty) {
        try {
          final match = await _matchService.getMatch(matchId);
          if (!mounted) return;
          setState(() {
            _match = match;
            _isLoading = false;
            _isRefreshing = false;
          });
          return;
        } on MatchApiException {
          if (args != null) {
            if (!mounted) return;
            setState(() {
              _match = _normalizeLocalMatch(args);
              _isLoading = false;
              _isRefreshing = false;
            });
            return;
          }
          rethrow;
        }
      }

      if (args != null) {
        if (!mounted) return;
        setState(() {
          _match = _normalizeLocalMatch(args);
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      throw const MatchApiException(
          message: 'Match not found', statusCode: 404);
    } on MatchApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load match details right now.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String? _matchIdFromArgs(Map<String, dynamic>? args) {
    if (args == null) return null;
    final matchId = args['id'] ?? args['matchGroupId'] ?? args['match_id'];
    if (matchId is String && matchId.isNotEmpty) return matchId;
    return null;
  }

  Map<String, dynamic> _normalizeLocalMatch(Map<String, dynamic> raw) {
    final members =
        (raw['members'] as List? ?? const []).whereType<Map>().map((item) {
      final member = item.cast<String, dynamic>();
      return {
        'id': member['id']?.toString() ?? member['name']?.toString() ?? '',
        'name': member['name']?.toString() ?? '',
        'avatarUrl': member['avatarUrl']?.toString() ?? '',
        'skillLevel': member['skillLevel']?.toString() ?? '',
        'eloRating':
            member['eloRating'] is num ? member['eloRating'] as num : 0,
        'position': member['position']?.toString() ?? '—',
        'team': member['team']?.toString() ?? '—',
        'status': member['status']?.toString() ?? 'confirmed',
        'isAdmin': member['isAdmin'] == true,
        'joinedAt': member['joinedAt']?.toString() ?? member['created_at']?.toString() ?? '',
      };
    }).toList(growable: false);
    final confirmedCount = members
      .where((member) => member['status']?.toString() == 'confirmed')
      .length;
    final maxPlayers =
      raw['maxPlayers'] is num ? (raw['maxPlayers'] as num).toInt() : 0;
    final spotsLeft =
      raw['spotsLeft'] is num ? (raw['spotsLeft'] as num).toInt() : 0;
    final slotsAvailable = raw['slotsAvailable'] is num
      ? (raw['slotsAvailable'] as num).toInt()
      : spotsLeft;
    final rawPlayersNeeded = raw['playersNeeded'];
    final playersNeeded = rawPlayersNeeded is num
      ? rawPlayersNeeded.toInt()
      : (maxPlayers > confirmedCount ? maxPlayers - confirmedCount : 0);
    final costSplitMode = raw['costSplitMode']?.toString() ?? '';
    final description = raw['description']?.toString() ?? '';
    final fillStatus = raw['fillStatus']?.toString() ?? '';
    final isPartialTeamBooking =
      raw['isPartialTeamBooking'] == true ||
        costSplitMode.isNotEmpty ||
        description.isNotEmpty;

    return {
      'id': raw['id']?.toString() ?? '',
      'venueName': raw['venueName']?.toString() ?? '',
      'venueImage': raw['venueImage']?.toString() ?? '',
      'venueAddress': raw['venueAddress']?.toString() ?? '',
      'courtName': raw['courtName']?.toString() ?? '',
      'courtType': raw['courtType']?.toString() ?? '',
      'courtSurface': raw['courtSurface']?.toString() ?? '',
      'date': raw['date']?.toString() ?? '',
      'matchDate': raw['matchDate']?.toString() ?? '',
      'time': raw['time']?.toString() ?? '',
      'endTime': raw['endTime']?.toString() ?? '',
      'spotsLeft': spotsLeft,
      'maxPlayers': maxPlayers,
      'memberCount': confirmedCount,
      'slotsAvailable': slotsAvailable,
      'playersNeeded': playersNeeded,
      'skillLevel': raw['skillLevel']?.toString() ?? '',
      'skillFilter': raw['skillFilter']?.toString() ?? '',
      'distance': raw['distance']?.toString() ?? '—',
      'fillStatus': fillStatus,
      'costSplitMode': costSplitMode,
      'description': description,
      'isPartialTeamBooking': isPartialTeamBooking,
      'friendsIn': raw['friendsIn'] is num ? raw['friendsIn'] as num : 0,
      'isOpen': raw['isOpen'] == true,
      'isAdmin': raw['isAdmin'] == true,
      'adminId': raw['adminId']?.toString() ?? '',
      'matchGroupId':
          raw['matchGroupId']?.toString() ?? raw['id']?.toString() ?? '',
      'inviteToken': raw['inviteToken']?.toString() ?? '',
      'inviteExpiresAt': raw['inviteExpiresAt']?.toString() ?? '',
      'resultWinner': raw['resultWinner']?.toString() ?? '',
      'members': members,
      'confirmedMembers': members
          .where((member) => member['status'] == 'confirmed')
          .toList(growable: false),
      'pendingMembers': const <Map<String, dynamic>>[],
      'currentUserMember': const <String, dynamic>{},
      'venue': {
        'name': raw['venueName']?.toString() ?? '',
        'cover_image_url': raw['venueImage']?.toString() ?? '',
        'address': raw['venueAddress']?.toString() ?? '',
      },
      'court': {
        'name': raw['courtName']?.toString() ?? '',
        'court_type': raw['courtType']?.toString() ?? '',
        'surface': raw['courtSurface']?.toString() ?? '',
      },
    };
  }

  bool get _isAdmin => _match?['isAdmin'] == true;

  bool get _isLoggedIn => _currentUserId != null && _currentUserId!.isNotEmpty;

  bool get _isCurrentUserMember {
    final members = _members;
    if (_currentUserId == null) return false;
    return members.any((member) => member['id']?.toString() == _currentUserId);
  }

  bool get _hasPendingJoinRequest {
    final pending = _pendingMembers;
    if (_currentUserId == null) return false;
    return pending.any((member) => member['id']?.toString() == _currentUserId);
  }

  bool get _isJoinable {
    final isOpen = _match?['isOpen'] == true;
    final isPartialTeamBooking = _match?['isPartialTeamBooking'] == true;
    final rawSlots = _match?['slotsAvailable'];
    final slotsAvailable =
        (rawSlots is num ? rawSlots : 0).toInt();
    final alreadyJoined = _isCurrentUserMember || _hasPendingJoinRequest;
    return (isOpen || isPartialTeamBooking) && slotsAvailable > 0 && !alreadyJoined;
  }

  String get _matchId => _match?['id']?.toString() ?? '';

  List<Map<String, dynamic>> get _members =>
      (_match?['members'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);

  List<Map<String, dynamic>> get _pendingMembers =>
      (_match?['pendingMembers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);

  String _displayTimeRange() {
    final start = _match?['time']?.toString() ?? '';
    final end = _match?['endTime']?.toString() ?? '';
    if (start.isEmpty && end.isEmpty) return '';
    return end.isEmpty ? start : '$start - $end';
  }

  Future<void> _joinMatch() async {
    if (!_isLoggedIn) {
      _goToLogin();
      return;
    }

    if (_matchId.isEmpty) return;

    // Prevent duplicate join requests - check if user is already a member or has pending request
    if (_isCurrentUserMember || _hasPendingJoinRequest) {
      if (!mounted) return;
      final message = _hasPendingJoinRequest
          ? 'You already have a pending join request.'
          : 'You have already joined this match.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.joinMatch(
        matchId: _matchId,
      );
      if (!mounted) return;

      // Refresh match data to update slots and show user as joined
      await _loadMatch(refresh: true);

      messenger.showSnackBar(
        const SnackBar(content: Text('Successfully joined the match!')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;

      // Handle 409 Conflict - user already joined or has pending request
      if (e.statusCode == 409) {
        messenger.showSnackBar(
          const SnackBar(content: Text('You have already joined this match.')),
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not join match right now')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _copyInviteLink() async {
    if (_matchId.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _matchService.generateInviteLink(_matchId);
      final url = response['url']?.toString() ?? '';
      final token = response['token']?.toString() ?? '';
      if (url.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: url));
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invite Link'),
          content: SelectableText(url.isNotEmpty ? url : token),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: url.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate invite link')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _approveMember(String userId) async {
    if (_matchId.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.approveMember(matchId: _matchId, userId: userId);
      if (!mounted) return;
      await _loadMatch(refresh: true);
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _rejectMember(String userId) async {
    if (_matchId.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.rejectMember(matchId: _matchId, userId: userId);
      if (!mounted) return;
      await _loadMatch(refresh: true);
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAddFriendBottomSheet() async {
    if (!mounted) return;
    final friends = await PlayerFriendsService.instance.getFriends();

    if (!mounted) return;

    final existingMemberIds = _members
        .map((m) => m['id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    showModalBottomSheet<void>(
      context: context,
      builder: (bottomContext) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(bottomContext).size.height * 0.7),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Add Friend to Match',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppFontWeights.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'No friends available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtDisabled),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...friends.map((friend) {
                final friendId = friend['id']?.toString() ?? '';
                final friendName = friend['name']?.toString() ?? 'Unknown';
                final avatarUrl = friend['avatarUrl']?.toString() ?? '';
                final skillLevel = friend['skillLevel']?.toString() ?? '';
                final isAlreadyInMatch = existingMemberIds.contains(friendId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    child: InkWell(
                      onTap: friendId.isEmpty || isAlreadyInMatch
                          ? null
                          : () async {
                              Navigator.pop(bottomContext);
                              await _addFriendToMatch(friendId, friendName);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.bgPrimary,
                          border: Border.all(color: AppColors.txtDisabled.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.bgPrimary,
                              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      friendName.isNotEmpty ? friendName.substring(0, 1).toUpperCase() : '?',
                                      style: Theme.of(context).textTheme.labelMedium,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(friendName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: AppFontWeights.semiBold)),
                                  if (skillLevel.isNotEmpty)
                                    Text(skillLevel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.txtDisabled)),
                                ],
                              ),
                            ),
                            if (isAlreadyInMatch)
                              Text(
                                'Added',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.txtDisabled,
                                  fontWeight: AppFontWeights.medium,
                                ),
                              )
                            else
                              const Icon(Icons.add_circle_outline, color: AppColors.green, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _addFriendToMatch(String friendId, String friendName) async {
    if (_matchId.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.addFriendToMatch(matchId: _matchId, friendId: friendId);
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        SnackBar(content: Text('Added $friendName to match')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add friend to match')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/login');
  }

  Color _skillColor(String? skillLevel) {
    return switch (skillLevel?.toLowerCase().trim()) {
      'advanced' => AppColors.red,
      'intermediate' => AppColors.amber,
      'beginner' => AppColors.green,
      _ => AppColors.blue,
    };
  }

  Widget _buildSlotVisualization(int confirmedCount, int maxPlayers, int slotsAvailable, BuildContext context) {
    final confirmedMembers = _members.where((m) => m['status'] == 'confirmed').toList();
    final emptySlots = maxPlayers - confirmedCount;
    final progress = maxPlayers > 0 ? confirmedCount / maxPlayers : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 18, color: AppColors.textSecondary()),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Player Slots',
                style: AppTypography.textTheme(Theme.of(context).colorScheme).titleSmall?.copyWith(
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progress >= 1.0
                    ? AppColors.green.withValues(alpha: 0.15)
                    : AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '$confirmedCount/$maxPlayers',
                  style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                    color: progress >= 1.0 ? AppColors.green : AppColors.amber,
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxs),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.green : AppColors.blue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Player slots grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.0,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
            ),
            itemCount: maxPlayers,
            itemBuilder: (context, index) {
              if (index < confirmedMembers.length) {
                final member = confirmedMembers[index];
                return _buildPlayerSlot(member, context);
              } else {
                return _buildEmptySlot(index - confirmedMembers.length < slotsAvailable, context);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          // Player names below grid
          if (confirmedMembers.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: confirmedMembers.map((member) {
                final name = member['name']?.toString() ?? 'Unknown';
                final joinedAt = member['joinedAt']?.toString() ?? '';
                final bookingTime = _formatBookingTime(joinedAt);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 12, color: AppColors.green),
                    const SizedBox(width: 4),
                    Text(
                      name,
                      style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                      ),
                    ),
                    if (bookingTime.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($bookingTime)',
                        style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                          color: AppColors.textSecondary(),
                        ),
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$confirmedCount confirmed • $emptySlots open',
                style: AppTypography.textTheme(Theme.of(context).colorScheme).bodySmall?.copyWith(
                  color: AppColors.textSecondary(),
                ),
              ),
              if (slotsAvailable > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.login_rounded, size: 12, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        '$slotsAvailable spot${slotsAvailable == 1 ? '' : 's'} left',
                        style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                          color: AppColors.green,
                          fontWeight: AppFontWeights.semiBold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(Map<String, dynamic> member, BuildContext context) {
    final name = member['name']?.toString() ?? 'Unknown';
    final avatarUrl = member['avatarUrl']?.toString() ?? '';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final isAdmin = member['isAdmin'] == true;
    final skillLevel = member['skillLevel']?.toString() ?? '';

    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.green.withValues(alpha: 0.12),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Text(
                  initials,
                  style: AppTypography.textTheme(Theme.of(context).colorScheme).titleSmall?.copyWith(
                    color: AppColors.green,
                    fontWeight: AppFontWeights.bold,
                  ),
                )
              : null,
        ),
        if (isAdmin)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgPrimary, width: 2),
              ),
              child: Icon(Icons.star, size: 8, color: AppColors.bgPrimary),
            ),
          ),
        if (skillLevel.isNotEmpty && skillLevel != 'All')
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _skillColor(skillLevel),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgPrimary, width: 2),
              ),
              child: Icon(
                skillLevel == 'Advanced' ? Icons.bolt : Icons.trending_up,
                size: 8,
                color: AppColors.bgPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySlot(bool isAvailable, BuildContext context) {
    return CircleAvatar(
      backgroundColor: isAvailable ? AppColors.bgElevated : AppColors.bgElevated.withValues(alpha: 0.3),
      child: Icon(
        isAvailable ? Icons.add_rounded : Icons.lock_outline,
        size: 18,
        color: isAvailable ? AppColors.textSecondary() : AppColors.textDisabled(),
      ),
    );
  }

  String _formatBookingTime(String? joinedAt) {
    if (joinedAt == null || joinedAt.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(joinedAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildConfirmedPlayersList(List<Map<String, dynamic>> members, BuildContext context) {
    final confirmed = members.where((m) => m['status'] == 'confirmed').toList();
    if (confirmed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 20, color: AppColors.textSecondary()),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Confirmed Players',
              style: AppTypography.textTheme(Theme.of(context).colorScheme).titleMedium?.copyWith(
                fontWeight: AppFontWeights.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${confirmed.length} player${confirmed.length == 1 ? '' : 's'}',
              style: AppTypography.textTheme(Theme.of(context).colorScheme).bodySmall?.copyWith(
                color: AppColors.textSecondary(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: confirmed.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final isLast = index == confirmed.length - 1;
              final position = member['position']?.toString() ?? '—';
              final joinedAt = member['joinedAt']?.toString() ?? '';
              final bookingTime = _formatBookingTime(joinedAt);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        _buildMemberAvatar(member, size: 40),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name']?.toString() ?? 'Unknown',
                                style: AppTypography.textTheme(Theme.of(context).colorScheme).bodyMedium?.copyWith(
                                  fontWeight: AppFontWeights.semiBold,
                                ),
                              ),
                              if (member['skillLevel']?.toString().isNotEmpty == true)
                                Text(
                                  member['skillLevel'].toString(),
                                  style: AppTypography.textTheme(Theme.of(context).colorScheme).bodySmall?.copyWith(
                                    color: AppColors.textSecondary(),
                                  ),
                                ),
                              if (bookingTime.isNotEmpty)
                                Text(
                                  'Joined $bookingTime',
                                  style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                                    color: AppColors.green,
                                    fontWeight: AppFontWeights.semiBold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            position.toUpperCase(),
                            style: AppTypography.textTheme(Theme.of(context).colorScheme).labelSmall?.copyWith(
                              color: AppColors.textSecondary(),
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: AppColors.borderClr),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatar(Map<String, dynamic> member, {double size = 40}) {
    final name = member['name']?.toString() ?? '?';
    final avatarUrl = member['avatarUrl']?.toString() ?? '';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final isAdmin = member['isAdmin'] == true;

    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: isAdmin ? AppColors.amber.withValues(alpha: 0.2) : AppColors.bgElevated,
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
            ? Text(
                initials,
                style: AppTypography.textTheme(Theme.of(context).colorScheme).titleSmall?.copyWith(
                  color: isAdmin ? AppColors.amber : AppColors.txtPrimary,
                  fontWeight: AppFontWeights.bold,
                ),
              )
            : null,
        ),
        if (isAdmin)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgPrimary, width: 2),
              ),
              child: Icon(Icons.star, size: 10, color: AppColors.bgPrimary),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _match == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _match == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage ?? 'Could not load match details.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtDisabled),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _loadMatch,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final match = _match ?? const <String, dynamic>{};
    final venueName = match['venueName']?.toString() ?? '';
    final venueAddress = match['venueAddress']?.toString() ?? '';
    final dateLabel = match['date']?.toString() ?? '';
    final timeLabel = _displayTimeRange();
    final members = _members;
    final confirmedCount =
        members.where((member) => member['status'] == 'confirmed').length;
    final maxPlayers =
        (match['maxPlayers'] is num ? match['maxPlayers'] as num : 0).toInt();
    final slotsAvailable =
      (match['slotsAvailable'] is num ? match['slotsAvailable'] as num : 0)
        .toInt();
    final playersNeeded =
      (match['playersNeeded'] is num ? match['playersNeeded'] as num : 0)
        .toInt();
    final isPartialTeamBooking = match['isPartialTeamBooking'] == true;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            iconTheme: IconThemeData(color: AppColors.txtPrimary),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.txtPrimary),
                onPressed:
                    _isRefreshing ? null : () => _loadMatch(refresh: true),
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: AppColors.txtPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 72,
                bottom: 14,
                end: 16,
              ),
              title: Text(venueName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: AppFontWeights.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if ((match['venueImage']?.toString() ?? '').isNotEmpty)
                    Image.network(
                      match['venueImage'].toString(),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: AppColors.bgPrimary),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.bgPrimary.withValues(alpha: 0.94),
                        ],
                        stops: const [0.42, 1.0],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: FootballFieldPainter(),
                    child: const SizedBox.expand(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Match Group', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Text(
                            venueName,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: AppFontWeights.extraBold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateLabel · $timeLabel',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _StatCol(
                                value: '$confirmedCount/$maxPlayers',
                                label: 'Players',
                                color: AppColors.green,
                              ),
                              const VerticalDivider(),
                              _StatCol(
                                value: match['skillLevel']?.toString() ?? 'All',
                                label: 'Skill',
                                color: _skillColor(match['skillLevel']?.toString()),
                              ),
                              const VerticalDivider(),
                              _StatCol(
                                value: match['distance']?.toString() ?? '—',
                                label: 'Distance',
                                color: AppColors.blue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.txtDisabled),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                venueAddress,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            StatusBadge(
                              label: isPartialTeamBooking
                                  ? 'Partial Team'
                                  : (match['isOpen'] == true
                                      ? 'Open Match'
                                      : 'Private'),
                              color: (match['isOpen'] == true ||
                                      isPartialTeamBooking)
                                  ? AppColors.green
                                  : AppColors.txtDisabled,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Players needed: $playersNeeded',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.txtDisabled),
                              ),
                            ),
                            Text(
                              'Slots available: $slotsAvailable',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.green,
                                    fontWeight: AppFontWeights.semiBold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSlotVisualization(confirmedCount, maxPlayers, slotsAvailable, context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildConfirmedPlayersList(members, context),
                  const SizedBox(height: 20),
                  Text('Invite Friends', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: 12),
                  if (_isAdmin) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add friends directly',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: AppFontWeights.semiBold),
                                ),
                                Text(
                                  'Invite friends from your friend list to the match',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _showAddFriendBottomSheet,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text(
                              'Add',
                              style: AppTypography.textTheme(Theme.of(context).colorScheme).labelLarge?.copyWith(color: AppColors.bgPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate share link',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: AppFontWeights.semiBold),
                              ),
                              Text(
                                match['inviteToken']?.toString().isNotEmpty == true
                                    ? 'Invite link is already active'
                                    : 'Create a new invite link for friends',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isAdmin ? _copyInviteLink : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(
                            'Copy Link',
                            style: AppTypography.textTheme(Theme.of(context).colorScheme).labelLarge?.copyWith(color: AppColors.bgPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_pendingMembers.isNotEmpty && _isAdmin) ...[
                    Text('Pending Requests', style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).headlineMedium),
                    const SizedBox(height: 12),
                    ..._pendingMembers.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.bgElevated,
                                backgroundImage: (member['avatarUrl']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true)
                                    ? NetworkImage(
                                        member['avatarUrl'].toString())
                                    : null,
                                child: (member['avatarUrl']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true)
                                    ? null
                                    : Text(
                                        (member['name']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                            ? member['name']
                                                .toString()
                                                .substring(0, 1)
                                            : '?',
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member['name']?.toString() ?? '-',
                                        style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodyMedium),
                                    Text(member['position']?.toString() ?? '-',
                                        style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodySmall),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _approveMember(
                                        member['id']?.toString() ?? ''),
                                child: Text(
                                  'Approve',
                                  style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _rejectMember(
                                        member['id']?.toString() ?? ''),
                                child: Text(
                                  'Reject',
                                  style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodyMedium?.copyWith(color: AppColors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(top: BorderSide(color: AppColors.borderClr)),
        ),
        child: _isCurrentUserMember
            ? FutsButton(
                label: 'Continue',
                outlined: true,
                onPressed: _isSubmitting ? null : () {},
              )
            : _hasPendingJoinRequest
                ? const FutsButton(
                    label: 'Request Pending',
                    outlined: true,
                    onPressed: null,
                  )
                : _isLoggedIn
                    ? FutsButton(
                        label: isPartialTeamBooking
                            ? 'Join Match & Play'
                            : 'Join Match',
                        isLoading: _isSubmitting,
                        onPressed: _isJoinable ? _joinMatch : null,
                      )
                    : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutsButton(
                        label: 'Sign In to Join',
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                      const SizedBox(height: 12),
                      FutsButton(
                        label: 'Create Account',
                        outlined: true,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCol({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).headlineMedium?.copyWith(color: color)),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodySmall),
        ],
      ),
    );
  }
}
