import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/player_auth_storage_service.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../shared/widgets/futs_button.dart';
import 'data/services/player_match_service.dart';
import '../friends/data/services/player_friends_service.dart';
import '../venues/data/services/player_venues_service.dart';
import 'presentation/widgets/match_hero_header.dart';
import 'presentation/widgets/match_info_strip.dart';
import 'presentation/widgets/player_list_section.dart';
import 'presentation/widgets/invite_section.dart';
import 'presentation/widgets/pending_requests_section.dart';
import '../../core/utils/time_formatters.dart';


class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final PlayerMatchService _matchService = PlayerMatchService.instance;
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _currentUserId;
  Map<String, dynamic>? _match;
  bool _initialized = false;
  bool _showCollapsedTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final showTitle = _scrollController.offset > 170;
    if (showTitle != _showCollapsedTitle && mounted) {
      setState(() => _showCollapsedTitle = showTitle);
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadMatch();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

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
          var match = await _matchService.getMatch(matchId);
          
          // Fetch venue details if amenities or address are missing
          final venueId = match['venueId']?.toString() ?? match['venue']?['id']?.toString() ?? '';
          final amenities = match['amenities'] as List? ?? const [];
          final address = match['venueAddress']?.toString() ?? '';
          
          if (venueId.isNotEmpty && (amenities.isEmpty || address.isEmpty)) {
            try {
              final venueDetail = await PlayerVenuesService.instance.getVenueDetail(venueId);
              match = {
                ...match,
                if (address.isEmpty) 'venueAddress': venueDetail['address'] ?? address,
                if (amenities.isEmpty) 'amenities': venueDetail['amenities'] ?? amenities,
                'venue': {
                  ...(match['venue'] as Map? ?? {}),
                  ...venueDetail,
                },
              };
            } catch (e) {
              debugPrint('Could not fetch venue details: $e');
            }
          }

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
      'venueId': raw['venueId']?.toString() ?? raw['venue']?['id']?.toString() ?? '',
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
      'amenities': (raw['amenities'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
    };
  }

  // ── Computed Properties ───────────────────────────────────────────────────

  bool get _isAdmin => _match?['isAdmin'] == true;
  bool get _isLoggedIn => _currentUserId != null && _currentUserId!.isNotEmpty;

  bool get _isCurrentUserMember {
    if (_currentUserId == null) return false;
    return _members.any((m) => m['id']?.toString() == _currentUserId);
  }

  bool get _hasPendingJoinRequest {
    if (_currentUserId == null) return false;
    return _pendingMembers.any((m) => m['id']?.toString() == _currentUserId);
  }

  bool get _isJoinable {
    final isOpen = _match?['isOpen'] == true;
    final isPartial = _match?['isPartialTeamBooking'] == true;
    final rawSlots = _match?['slotsAvailable'];
    final slots = (rawSlots is num ? rawSlots : 0).toInt();
    final alreadyJoined = _isCurrentUserMember || _hasPendingJoinRequest;
    return (isOpen || isPartial) && slots > 0 && !alreadyJoined;
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
    return formatClockTimeRange12Hour(start, end);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _joinMatch() async {
    if (!_isLoggedIn) {
      _goToLogin();
      return;
    }
    if (_matchId.isEmpty) return;

    // Prevent duplicate join requests
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
      await _matchService.joinMatch(matchId: _matchId);
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Successfully joined the match!')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
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

  Future<void> _handleRemovePlayer(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player?'),
        content: const Text('Are you sure you want to remove this player from the match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rejectMember(userId);
    }
  }

  void _handleViewProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/profile/user',
      arguments: {'userId': userId},
    );
  }

  Future<void> _showAddFriendBottomSheet() async {
    if (!mounted) return;
    final friends = await PlayerFriendsService.instance.getFriends();
    if (!mounted) return;

    final memberStatusById = <String, String>{};
    for (final member in _members) {
      final id = member['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      memberStatusById[id] =
          member['status']?.toString().toLowerCase() ?? 'confirmed';
    }
    for (final member in _pendingMembers) {
      final id = member['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      memberStatusById[id] = 'pending';
    }

    final validFriends = friends
        .where((friend) => (friend['id']?.toString() ?? '').isNotEmpty)
        .toList(growable: false);
    final selectableFriendCount = validFriends.where((friend) {
      final friendId = friend['id']?.toString() ?? '';
      return !memberStatusById.containsKey(friendId);
    }).length;

    final Set<String> selectedFriendIds = {};

    // Calculate players needed just for UI text
    final rawSlots = _match?['slotsAvailable'];
    final slotsAvailable = (rawSlots is num ? rawSlots : 0).toInt();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (bottomContext) {
        final scheme = Theme.of(bottomContext).colorScheme;
        final tt = AppTypography.textTheme(scheme);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCount = selectedFriendIds.length;
            final cappedSelectableCount = slotsAvailable < selectableFriendCount
                ? slotsAvailable
                : selectableFriendCount;
            final subtitle = slotsAvailable <= 0
                ? 'This match is already full'
                : validFriends.isEmpty
                    ? 'No friends available to add'
                : selectableFriendCount == 0
                    ? 'All available friends are already in this match'
                    : 'Select up to $cappedSelectableCount friend${cappedSelectableCount == 1 ? '' : 's'} for the remaining $slotsAvailable spot${slotsAvailable == 1 ? '' : 's'}';
            final actionLabel = selectedCount > 0
                ? 'Add $selectedCount Friend${selectedCount == 1 ? '' : 's'}'
                : slotsAvailable <= 0
                    ? 'Match is Full'
                    : validFriends.isEmpty
                        ? 'No Friends Available'
                        : selectableFriendCount == 0
                            ? 'All Friends Added'
                            : 'Select Friends';

            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(bottomContext).size.height * 0.65),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: AppSpacing.xxxl, bottom: AppSpacing.xxxl),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 24, color: scheme.primary),
                              const SizedBox(width: AppSpacing.xxl),
                              Expanded(
                                child: Text('Add Friend to Match',
                                    style: tt.titleLarge?.copyWith(fontWeight: AppFontWeights.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                          child: Text(
                            subtitle,
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (validFriends.isEmpty)
                          _AddFriendEmptyState(
                            icon: Icons.person_add_disabled_rounded,
                            title: 'No friends available',
                            message: 'Accepted friends will appear here.',
                            textTheme: tt,
                            colorScheme: scheme,
                          )
                        else
                          ...validFriends.asMap().entries.map((entry) {
                            final index = entry.key;
                            final friend = entry.value;
                            final fId = friend['id']?.toString() ?? '';
                            final fName = friend['name']?.toString() ?? 'Unknown';
                            final avatarUrl = friend['avatarUrl']?.toString() ?? '';
                            final skillLevel = friend['skillLevel']?.toString() ?? '';
                            final memberStatus = memberStatusById[fId];
                            final alreadyIn = memberStatus != null;
                            final isConfirmed = memberStatus == 'confirmed';
                            final isPending = memberStatus == 'pending';
                            final isSelected = selectedFriendIds.contains(fId);
                            final canSelect = !alreadyIn &&
                                slotsAvailable > 0 &&
                                (selectedFriendIds.length < slotsAvailable ||
                                    isSelected);
                            final limitReached = !alreadyIn &&
                                !isSelected &&
                                selectedFriendIds.length >= slotsAvailable;

                            if (fId.isEmpty) return const SizedBox.shrink();

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: canSelect
                                      ? () {
                                          setModalState(() {
                                            if (isSelected) {
                                              selectedFriendIds.remove(fId);
                                            } else {
                                              selectedFriendIds.add(fId);
                                            }
                                          });
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxxl),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: scheme.surfaceContainerHighest,
                                          backgroundImage: avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          child: avatarUrl.isEmpty
                                              ? Text(
                                                  fName.isNotEmpty
                                                      ? fName.substring(0, 1).toUpperCase()
                                                      : '?',
                                                  style: tt.titleMedium?.copyWith(
                                                    fontWeight: AppFontWeights.semiBold,
                                                  ))
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.xxxl),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(fName,
                                                  style: tt.titleMedium?.copyWith(
                                                      fontWeight: AppFontWeights.semiBold)),
                                              const SizedBox(height: 2),
                                              if (skillLevel.isNotEmpty)
                                                Text(skillLevel,
                                                    style: tt.bodyMedium?.copyWith(
                                                        color: AppColors.textDisabled())),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xxl),
                                        if (alreadyIn)
                                          _AddFriendStatusChip(
                                            icon: isConfirmed
                                                ? Icons.check_circle_rounded
                                                : Icons.mark_email_read_outlined,
                                            label: isConfirmed
                                                ? 'Added'
                                                : isPending
                                                    ? 'Invited'
                                                    : 'Added',
                                            backgroundColor: (isPending
                                                    ? scheme.primary
                                                    : AppColors.green)
                                                .withOpacity(0.12),
                                            foregroundColor: isPending
                                                ? scheme.primary
                                                : AppColors.green,
                                            textTheme: tt,
                                          )
                                        else if (isSelected)
                                          _AddFriendStatusChip(
                                            icon: Icons.check_rounded,
                                            label: 'Selected',
                                            backgroundColor: scheme.primary.withOpacity(0.14),
                                            foregroundColor: scheme.primary,
                                            textTheme: tt,
                                          )
                                        else if (limitReached)
                                          _AddFriendStatusChip(
                                            icon: Icons.lock_outline_rounded,
                                            label: 'Full',
                                            backgroundColor: scheme.surfaceContainerHighest,
                                            foregroundColor: AppColors.textDisabled(),
                                            textTheme: tt,
                                          )
                                        else
                                          _AddFriendStatusChip(
                                            icon: Icons.add_rounded,
                                            label: 'Add',
                                            backgroundColor: scheme.primary,
                                            foregroundColor: scheme.onPrimary,
                                            textTheme: tt,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (index < validFriends.length - 1)
                                  Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: scheme.outlineVariant.withOpacity(0.3),
                                      indent: AppSpacing.xxxl + 56 + AppSpacing.xxxl),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border(
                        top: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.35),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: FutsButton(
                        label: actionLabel,
                        onPressed: selectedFriendIds.isEmpty
                            ? null
                            : () {
                                Navigator.pop(bottomContext);
                                _addFriendsToMatch(selectedFriendIds);
                              },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addFriendsToMatch(Set<String> friendIds) async {
    if (_matchId.isEmpty || friendIds.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    int successCount = 0;
    try {
      // Use matchGroupId for adding friends to match
      final matchGroupId = _match?['matchGroupId']?.toString() ?? '';
      if (matchGroupId.isEmpty) return;

      for (final friendId in friendIds) {
        await _matchService.addFriendToMatch(
            matchId: matchGroupId, friendId: friendId);
        successCount++;
      }
      if (!mounted) return;
      await _loadMatch(refresh: true);
      final friendLabel = successCount == 1 ? 'friend' : 'friends';
      messenger.showSnackBar(
        SnackBar(content: Text('Added $successCount $friendLabel to match')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      if (successCount > 0) await _loadMatch(refresh: true);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      if (successCount > 0) await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add friends to match')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/login');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading && _match == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_errorMessage != null && _match == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  _errorMessage ?? 'Could not load match details.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.txtDisabled),
                ),
                const SizedBox(height: AppSpacing.xxxl),
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

    // Extract match data
    final match = _match ?? const <String, dynamic>{};
    final venueName = match['venueName']?.toString() ?? '';
    final venueImage = match['venueImage']?.toString() ?? '';
    final venueAddress = match['venueAddress']?.toString() ?? '';
    final dateLabel = match['date']?.toString() ?? '';
    final timeLabel = _displayTimeRange();
    final members = _members;
    final confirmedCount = (match['memberCount'] is num ? match['memberCount'] as num : 0).toInt();
    final offlinePlayersCount = (match['offlinePlayersCount'] is num ? match['offlinePlayersCount'] as num : 0).toInt();
    final maxPlayers =
        (match['maxPlayers'] is num ? match['maxPlayers'] as num : 0).toInt();
    final slotsAvailable =
        (match['slotsAvailable'] is num ? match['slotsAvailable'] as num : 0)
            .toInt();
    final isPartialTeamBooking = match['isPartialTeamBooking'] == true;
    final skillLevel = match['skillLevel']?.toString() ?? 'All';
    final amenities = (match['amenities'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ── Hero Header (clean image like venue details) ────────────
            MatchHeroHeader(
              venueImage: venueImage,
              venueName: venueName,
              isRefreshing: _isRefreshing,
              onRefresh: () => _loadMatch(refresh: true),
              onShare: () => _copyInviteLink(),
              showCollapsedTitle: _showCollapsedTitle,
            ),

            // ── Unified Content Container ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Venue Name & Date/Time (below hero like venue details) ────
                  MatchHeaderContent(
                    venueName: venueName,
                    dateLabel: dateLabel,
                    timeLabel: timeLabel,
                    venueAddress: venueAddress,
                    amenities: amenities,
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xxs,
                      AppSpacing.md,
                      AppSpacing.xxs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info strip
                        MatchInfoStrip(
                          venueAddress: venueAddress,
                          skillLevel: skillLevel,
                          isPartialTeamBooking: isPartialTeamBooking,
                          isOpen: match['isOpen'] == true,
                          confirmedCount: confirmedCount,
                          maxPlayers: maxPlayers,
                          slotsAvailable: slotsAvailable,
                          offlinePlayersCount: offlinePlayersCount,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Players section
                        PlayerListSection(
                          members: members,
                          maxPlayers: maxPlayers,
                          slotsAvailable: slotsAvailable,
                          offlinePlayersCount: offlinePlayersCount,
                          isAdmin: _isAdmin,
                          isSubmitting: _isSubmitting,
                          onAddFriend: _showAddFriendBottomSheet,
                          onRemovePlayer: _handleRemovePlayer,
                          onViewProfile: _handleViewProfile,
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Invite section (only when slots available)
                        if (slotsAvailable > 0) ...[
                          InviteSection(
                            isAdmin: _isAdmin,
                            isSubmitting: _isSubmitting,
                            hasExistingInvite:
                                match['inviteToken']?.toString().isNotEmpty == true,
                            onCopyInviteLink: _copyInviteLink,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Pending requests (admin only)
                        if (_pendingMembers.isNotEmpty && _isAdmin) ...[
                          PendingRequestsSection(
                            pendingMembers: _pendingMembers,
                            isSubmitting: _isSubmitting,
                            onApprove: _approveMember,
                            onReject: _rejectMember,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Bottom spacing for the action bar
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Bottom Action Bar ───────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(isPartialTeamBooking),
    );
  }

  Widget? _buildBottomBar(bool isPartialTeamBooking) {
    // Already a member — no bottom bar needed
    if (_isCurrentUserMember) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderClr)),
      ),
      child: _hasPendingJoinRequest
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
                      onPressed: () =>
                          Navigator.pushNamed(context, '/login'),
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
    );
  }
}

class _AddFriendStatusChip extends StatelessWidget {
  const _AddFriendStatusChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: AppFontWeights.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFriendEmptyState extends StatelessWidget {
  const _AddFriendEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.textTheme,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String message;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.textDisabled(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeights.semiBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
