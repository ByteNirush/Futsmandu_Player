import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/painters/field_painter.dart';
import '../../core/services/player_auth_storage_service.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/services/player_match_service.dart';

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
  String? _selectedPosition = 'midfielder';
  String _selectedWinner = 'A';

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
    final playersNeeded = raw['playersNeeded'] is num
      ? (raw['playersNeeded'] as num).toInt()
      : math.max(0, maxPlayers - confirmedCount);
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

  bool get _isJoinable {
    final isOpen = _match?['isOpen'] == true;
    final isPartialTeamBooking = _match?['isPartialTeamBooking'] == true;
    final rawSlots = _match?['slotsAvailable'];
    final slotsAvailable =
        (rawSlots is num ? rawSlots : 0).toInt();
    return (isOpen || isPartialTeamBooking) && slotsAvailable > 0;
  }

  String get _matchId => _match?['id']?.toString() ?? '';

  List<Map<String, dynamic>> get _members =>
      (_match?['members'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);

  List<Map<String, dynamic>> get _confirmedMembers =>
      (_match?['confirmedMembers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);

  List<Map<String, dynamic>> get _pendingMembers =>
      (_match?['pendingMembers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);

  List<Map<String, dynamic>> _teamMembers(String team) {
    return _confirmedMembers
        .where((member) => member['team']?.toString() == team)
        .toList(growable: false);
  }

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

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.requestToJoinMatch(
        matchId: _matchId,
        position: _selectedPosition,
      );
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Requested to join match')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not join match right now')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _leaveMatch() async {
    if (_matchId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.leaveMatch(_matchId);
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Left match')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not leave match right now')),
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

  Future<void> _autoBalanceTeams() async {
    if (_matchId.isEmpty) return;

    final confirmed = List<Map<String, dynamic>>.from(_confirmedMembers);
    if (confirmed.isEmpty) return;

    final teamA = <String>[];
    final teamB = <String>[];
    for (var i = 0; i < confirmed.length; i++) {
      final memberId = confirmed[i]['id']?.toString();
      if (memberId == null || memberId.isEmpty) continue;
      if (i.isEven) {
        teamA.add(memberId);
      } else {
        teamB.add(memberId);
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.updateTeams(
          matchId: _matchId, teamA: teamA, teamB: teamB);
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Teams updated')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _recordResult() async {
    if (_matchId.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _matchService.recordResult(
          matchId: _matchId, winner: _selectedWinner);
      if (!mounted) return;
      await _loadMatch(refresh: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Result recorded')),
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/login');
  }

  Color _skillColor(String skillLevel) {
    return switch (skillLevel) {
      'Advanced' => AppColors.red,
      'Intermediate' => AppColors.amber,
      'Beginner' => AppColors.green,
      _ => AppColors.txtDisabled,
    };
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
    final teamA = _teamMembers('A');
    final teamB = _teamMembers('B');
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
                  FutsCard(
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
                                color: _skillColor(
                                    match['skillLevel']?.toString() ?? ''),
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
                  Row(
                    children: [
                      Text('Teams', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppFontWeights.bold)),
                      const Spacer(),
                      Text('$confirmedCount/$maxPlayers players',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TeamColumn(
                            team: 'A', color: AppColors.green, members: teamA),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TeamColumn(
                            team: 'B', color: AppColors.blue, members: teamB),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Invite Friends', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: 12),
                  FutsCard(
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
                                match['inviteToken']?.toString().isNotEmpty ==
                                        true
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(
                            'Copy Link',
                            style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).labelLarge?.copyWith(
                        color: AppColors.bgPrimary,
                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isAdmin) ...[
                    Text('Admin Tools', style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).headlineMedium),
                    const SizedBox(height: 12),
                    FutsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FutsButton(
                                  label: 'Auto Balance Teams',
                                  isLoading: _isSubmitting,
                                  onPressed: _autoBalanceTeams,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedWinner,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'A', child: Text('Team A')),
                                    DropdownMenuItem(
                                        value: 'B', child: Text('Team B')),
                                    DropdownMenuItem(
                                        value: 'draw', child: Text('Draw')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedWinner = value);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                      labelText: 'Match Result'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: FutsButton(
                                  label: 'Save Result',
                                  isLoading: _isSubmitting,
                                  onPressed: _recordResult,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_pendingMembers.isNotEmpty && _isAdmin) ...[
                    Text('Pending Requests', style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).headlineMedium),
                    const SizedBox(height: 12),
                    ..._pendingMembers.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs2),
                        child: FutsCard(
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
                label: _isAdmin ? 'Admin Member' : 'Leave Match',
                outlined: true,
                customColor: AppColors.red,
                onPressed: _isAdmin || _isSubmitting ? null : _leaveMatch,
              )
            : _isLoggedIn
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ('GK', 'goalkeeper'),
                            ('DEF', 'defender'),
                            ('MID', 'midfielder'),
                            ('FWD', 'striker'),
                          ].map((entry) {
                            final label = entry.$1;
                            final apiValue = entry.$2;
                            final isSelected = _selectedPosition == apiValue;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedPosition = apiValue),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin:
                                    const EdgeInsets.only(right: AppSpacing.xs),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.green
                                      : AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.green
                                        : AppColors.borderClr,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodyMedium?.copyWith(
                                    fontWeight: AppFontWeights.semiBold,
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
                      const SizedBox(height: 10),
                      FutsButton(
                        label: isPartialTeamBooking
                            ? 'Join Match & Play'
                            : 'Join Match',
                        isLoading: _isSubmitting,
                        onPressed: !_isJoinable || _selectedPosition == null
                            ? null
                            : _joinMatch,
                      ),
                    ],
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

class _TeamColumn extends StatelessWidget {
  final String team;
  final Color color;
  final List<Map<String, dynamic>> members;

  const _TeamColumn({
    required this.team,
    required this.color,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final int emptySlots = math.max(0, 5 - members.length);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs2),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    team,
                    style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodySmall?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                        color: color,
                      ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Team $team', style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).headlineMedium?.copyWith(fontSize: 16)),
              const Spacer(),
              Text('${members.length}/5', style: AppTypography.textTheme(
                        Theme.of(context).colorScheme,
                      ).bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((member) => _MemberRow(m: member)),
          ...List.generate(emptySlots, (_) {
            return Container(
              height: 34,
              margin: const EdgeInsets.only(top: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Empty slot',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.txtDisabled),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Map<String, dynamic> m;

  const _MemberRow({required this.m});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: (m['avatarUrl']?.toString().isNotEmpty == true)
                ? NetworkImage(m['avatarUrl'].toString())
                : null,
            child: (m['avatarUrl']?.toString().isNotEmpty == true)
                ? null
                : Text(
                    (m['name']?.toString().isNotEmpty == true)
                        ? m['name'].toString().substring(0, 1)
                        : '?',
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m['name'].toString().split(' ').first,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.txtPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(m['position']?.toString() ?? '—', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: AppFontWeights.semiBold)),
        ],
      ),
    );
  }
}
