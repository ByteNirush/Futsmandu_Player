import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/mock/mock_data.dart';
import '../../core/services/player_auth_storage_service.dart';
import '../../core/theme/app_colors.dart'; // only for AppColors.warning (semantic const)
import '../../features/matches/data/services/player_match_service.dart';
import '../../features/venues/data/services/player_venues_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_badge.dart';
import 'home_shell.dart' show kNavBarHeight;

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// ─────────────────────────────────────────────────────────────────────────────
// Email Nudge Banner
// ─────────────────────────────────────────────────────────────────────────────

class _EmailNudgeBanner extends StatefulWidget {
  const _EmailNudgeBanner();

  @override
  State<_EmailNudgeBanner> createState() => _EmailNudgeBannerState();
}

class _EmailNudgeBannerState extends State<_EmailNudgeBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.warning, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.mark_email_unread,
              size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Verify your email to enable bookings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Verify'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.warning),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Match Mini Card
// ─────────────────────────────────────────────────────────────────────────────

class _MatchMiniCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchMiniCard(this.match);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final int spotsLeft = match['spotsLeft'] as int? ?? 0;
    final Color spotsColor = spotsLeft <= 2
        ? colorScheme.error
        : spotsLeft <= 4
            ? AppColors.warning
            : colorScheme.primary;

    return SizedBox(
      width: 160,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/match-detail',
              arguments: match,
            ),
            child: Stack(
              children: [
                // Venue image
                CachedNetworkImage(
                  imageUrl: match['venueImage'] as String? ?? '',
                  fit: BoxFit.cover,
                  width: 160,
                  height: 200,
                  placeholder: (context, url) => Container(
                    width: 160,
                    height: 200,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 160,
                    height: 200,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Dark gradient overlay
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD9000000)],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),

                // Info overlay
                Positioned(
                  bottom: AppSpacing.xs3,
                  left: AppSpacing.xs3,
                  right: AppSpacing.xs3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(
                        label: '$spotsLeft spots',
                        color: spotsColor,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        match['venueName'] as String? ?? '',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              '${match['time']} · ${match['distance']}',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Friends-in badge
                if ((match['friendsIn'] as int? ?? 0) > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+${match['friendsIn']}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta Chip (icon + text row inside booking card)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming Booking Card
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingBookingCard extends StatelessWidget {
  final Map<String, dynamic> b;

  const _UpcomingBookingCard(this.b);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String? matchId = b['matchId'] as String?;
    Map<String, dynamic>? matchDetail;
    if (matchId != null) {
      for (final match in MockData.matches) {
        if (match['id'] == matchId) {
          matchDetail = match;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: matchDetail == null
          ? null
          : () => Navigator.pushNamed(
                context,
                '/match-detail',
                arguments: matchDetail,
              ),
      child: FutsCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs2),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    right: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            label: 'CONFIRMED',
                            color: colorScheme.primary,
                          ),
                          const Spacer(),
                          Text(
                            'NPR ${b['priceNPR']}',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        b['venueName'] as String? ?? '',
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        b['courtName'] as String? ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _MetaChip(
                            Icons.calendar_today,
                            (b['date'] as String? ?? '')
                                .split(' ')
                                .take(3)
                                .join(' '),
                          ),
                          const SizedBox(width: AppSpacing.xs2),
                          _MetaChip(
                            Icons.access_time,
                            b['time'] as String? ?? '',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Futsal Card
// ─────────────────────────────────────────────────────────────────────────────

class _TopFutsalCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _TopFutsalCard(this.venue);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/venues'),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: venue['coverUrl'] as String? ?? '',
                  fit: BoxFit.cover,
                  width: 220,
                  height: 140,
                  placeholder: (context, url) => Container(
                    width: 220,
                    height: 140,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 220,
                    height: 140,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Gradient overlay
                const SizedBox(
                  width: 220,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x1A000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                ),

                // Info overlay
                Positioned(
                  left: AppSpacing.xs3,
                  right: AppSpacing.xs3,
                  bottom: AppSpacing.xs3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue['name'] as String? ?? '',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              '${venue['rating']}${venue['distance'] != null && venue['distance'].toString().isNotEmpty ? '  ·  ${venue['distance']}' : ''}',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _currentUser =
      Map<String, dynamic>.from(MockData.currentUser);
  List<Map<String, dynamic>> _topFutsals = [];
  bool _isLoadingFutsals = true;
  String? _futsalsError;

  List<Map<String, dynamic>> _tonightMatches = [];
  bool _isLoadingTonightMatches = true;
  String? _tonightMatchesError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadTopFutsals();
    _loadTonightMatches();
  }

  Future<void> _loadCurrentUser() async {
    final user = await PlayerAuthStorageService.instance.getUser();
    if (!mounted || user == null) return;
    final mergedUser = Map<String, dynamic>.from(MockData.currentUser)
      ..addAll(user);
    setState(() => _currentUser = mergedUser);
  }

  Future<void> _loadTopFutsals() async {
    setState(() {
      _isLoadingFutsals = true;
      _futsalsError = null;
    });
    try {
      final venues = await PlayerVenuesService.instance.browseVenues(limit: 4);
      if (!mounted) return;
      final sortedVenues = venues.toList()
        ..sort(
          (a, b) =>
              ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num),
        );
      setState(() {
        _topFutsals = sortedVenues;
        _isLoadingFutsals = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _futsalsError = e.toString();
        _isLoadingFutsals = false;
      });
    }
  }

  Future<void> _loadTonightMatches() async {
    setState(() {
      _isLoadingTonightMatches = true;
      _tonightMatchesError = null;
    });
    try {
      final matches = await PlayerMatchService.instance.getTonightMatches();
      if (!mounted) return;
      setState(() {
        _tonightMatches = matches;
        _isLoadingTonightMatches = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tonightMatchesError = e.toString();
        _isLoadingTonightMatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final int score = _currentUser['reliabilityScore'] as int? ?? 100;
    final bool isVerified = _currentUser['isVerified'] as bool? ?? true;
    final String greeting = _greetingForHour(DateTime.now().hour);
    final String userName =
        (_currentUser['name']?.toString().trim().isNotEmpty ?? false)
            ? _currentUser['name'].toString().trim()
            : 'Player';
    final String avatarUrl = _currentUser['avatarUrl']?.toString() ?? '';
    final int notificationCount = MockData.notifications.length;

    Map<String, dynamic>? upcomingBooking;
    try {
      upcomingBooking =
          MockData.bookings.firstWhere((b) => b['status'] == 'CONFIRMED');
    } catch (_) {}

    return Scaffold(
      // scaffoldBackgroundColor is applied automatically from the theme.
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Email nudge banner ──────────────────────────────────────────
            if (!isVerified)
              const SliverToBoxAdapter(child: _EmailNudgeBanner()),

            // ── Greeting header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Greeting text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            userName,
                            style: textTheme.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Avatar with online status dot
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person_outline,
                                  color: colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                              border: Border.all(
                                // Match the scaffold background so the ring
                                // appears to "punch through" to the background.
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xxs),

                    // Notification bell with count badge
                    Badge(
                      label: Text(notificationCount.toString()),
                      isLabelVisible: notificationCount > 0,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: colorScheme.onSurfaceVariant,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Reliability warning ─────────────────────────────────────────
            if (score < 70)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    top: AppSpacing.xs2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.xs2),
                    border: const Border(
                      left: BorderSide(color: AppColors.warning, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Reliability score is $score. Attend bookings to improve.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Top Futsal section ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Top Futsal',
                      onAction: () => Navigator.pushNamed(context, '/venues'),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    if (_isLoadingFutsals)
                      _SectionPlaceholder(
                        height: 140,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    else if (_futsalsError != null)
                      _SectionPlaceholder(
                        height: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Failed to load venues',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _loadTopFutsals,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_topFutsals.isEmpty)
                      _SectionPlaceholder(
                        height: 140,
                        child: Text(
                          'No venues available',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          itemCount: math.min(4, _topFutsals.length),
                          itemBuilder: (ctx, i) =>
                              _TopFutsalCard(_topFutsals[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Play Tonight section ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Play Tonight',
                      onAction: () =>
                          Navigator.pushNamed(context, '/discovery'),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    if (_isLoadingTonightMatches)
                      _SectionPlaceholder(
                        height: 200,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    else if (_tonightMatchesError != null)
                      _SectionPlaceholder(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Failed to load matches',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _loadTonightMatches,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_tonightMatches.isEmpty)
                      _SectionPlaceholder(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_soccer_outlined,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No open matches tonight',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/discovery'),
                              child: const Text('Browse All'),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          itemCount: math.min(5, _tonightMatches.length),
                          itemBuilder: (ctx, i) =>
                              _MatchMiniCard(_tonightMatches[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Upcoming Booking section ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.md,
                  0,
                  MediaQuery.of(context).padding.bottom +
                      kNavBarHeight +
                      AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Upcoming',
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Use Bookings tab below'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    if (upcomingBooking != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _UpcomingBookingCard(upcomingBooking),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: EmptyState(
                          icon: Icons.sports_soccer_outlined,
                          title: 'No upcoming bookings',
                          subtitle: 'Find a court and book your next game',
                          buttonLabel: 'Browse Courts',
                          onButton: () =>
                              Navigator.pushNamed(context, '/venues'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared placeholder for loading / error / empty states within sections
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPlaceholder extends StatelessWidget {
  final double height;
  final Widget child;

  const _SectionPlaceholder({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.xs2),
        ),
        child: Center(child: child),
      ),
    );
  }
}
