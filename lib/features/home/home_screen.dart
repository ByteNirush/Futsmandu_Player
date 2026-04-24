import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/mock/mock_data.dart';
import '../../core/services/player_auth_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/booking/data/services/player_booking_service.dart';
import '../../features/matches/data/services/player_match_service.dart';
import '../../features/notifications/data/services/player_notifications_service.dart';
import '../../features/profile/data/services/player_profile_service.dart';
import '../../features/venues/data/services/player_venues_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_badge.dart';
import 'home_shell.dart' show kNavBarHeight;

const double _kMatchCardWidth = 160.0;
const double _kMatchCardHeight = 200.0;
const double _kVenueCardWidth = 220.0;
const double _kVenueCardHeight = 140.0;
const double _kSearchDropdownMaxHeight = 280.0;
const Duration _kSearchDebounce = Duration(milliseconds: 400);

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SmallSpinner extends StatelessWidget {
  const _SmallSpinner();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}

/// Handles loading → error → content lifecycle for each home section.
class _SectionBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final double placeholderHeight;
  final WidgetBuilder builder;

  const _SectionBody({
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.placeholderHeight,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _SectionPlaceholder(
        height: placeholderHeight,
        child: const _SmallSpinner(),
      );
    }
    if (error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      return _SectionPlaceholder(
        height: placeholderHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Failed to load',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return builder(context);
  }
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
          const Icon(Icons.mark_email_unread, size: 18, color: AppColors.warning),
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
      width: _kMatchCardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs2),
        child: Material(
          color: colorScheme.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/match-detail',
              arguments: match,
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: match['venueImage'] as String? ?? '',
                  fit: BoxFit.cover,
                  width: _kMatchCardWidth,
                  height: _kMatchCardHeight,
                  placeholder: (context, url) => Container(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const _SmallSpinner(),
                  ),
                  errorWidget: (context, url, error) => Container(
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
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0),
                          colorScheme.scrim.withValues(alpha: 0.85),
                        ],
                        stops: const [0.3, 1.0],
                      ),
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
                      StatusBadge(label: '$spotsLeft spots', color: spotsColor),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        match['venueName'] as String? ?? '',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              '${match['time']} · ${match['distance']}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.7),
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
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
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

    return FutsCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.pushNamed(context, '/bookings'),
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
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
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
                    Text(b['venueName'] as String? ?? '', style: textTheme.titleSmall),
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
                        _MetaChip(Icons.access_time, b['time'] as String? ?? ''),
                      ],
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
// Top Venue Card
// ─────────────────────────────────────────────────────────────────────────────

class _TopFutsalCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _TopFutsalCard(this.venue);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: _kVenueCardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs2),
        child: Material(
          color: colorScheme.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/venue-detail', arguments: venue),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: venue['coverUrl'] as String? ?? '',
                  fit: BoxFit.cover,
                  width: _kVenueCardWidth,
                  height: _kVenueCardHeight,
                  placeholder: (context, url) => Container(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const _SmallSpinner(),
                  ),
                  errorWidget: (context, url, error) => Container(
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
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.scrim.withValues(alpha: 0.10),
                          colorScheme.scrim.withValues(alpha: 0.80),
                        ],
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
                          color: colorScheme.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              '${venue['rating']}${venue['distance'] != null && venue['distance'].toString().isNotEmpty ? '  ·  ${venue['distance']}' : ''}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary.withValues(alpha: 0.9),
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

  List<Map<String, dynamic>> _upcomingBookings = [];
  bool _isLoadingBookings = true;

  int _unreadNotificationCount = 0;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchFieldKey = GlobalKey();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  double _searchDropdownTop = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadTopFutsals();
    _loadTonightMatches();
    _loadUpcomingBookings();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Fetch fresh profile data to get the latest avatar URL
      final profile = await PlayerProfileService.instance.getOwnProfile();
      if (!mounted) return;

      final user = await PlayerAuthStorageService.instance.getUser();
      final baseUser = Map<String, dynamic>.from(MockData.currentUser);

      if (user != null) {
        baseUser.addAll(user);
      }

      // Override with fresh profile data, mapping profileImageUrl to avatarUrl
      baseUser['name'] = profile.name;
      baseUser['email'] = profile.email;
      baseUser['avatarUrl'] = profile.profileImageUrl;
      baseUser['isVerified'] = profile.isVerified;
      baseUser['reliabilityScore'] = profile.reliabilityScore;
      baseUser['eloRating'] = profile.eloRating;

      setState(() => _currentUser = baseUser);
    } catch (_) {
      // Fallback to auth storage if profile fetch fails
      final user = await PlayerAuthStorageService.instance.getUser();
      if (!mounted || user == null) return;
      final mergedUser = Map<String, dynamic>.from(MockData.currentUser)
        ..addAll(user);
      setState(() => _currentUser = mergedUser);
    }
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

  Future<void> _loadUpcomingBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final result = await PlayerBookingService.instance.getBookings(
        status: 'CONFIRMED',
        limit: 3,
      );
      if (!mounted) return;
      setState(() {
        _upcomingBookings =
            result.items.map((item) => item.toMap()).toList(growable: false);
        _isLoadingBookings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBookings = false);
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final page =
          await PlayerNotificationsService.instance.getNotifications(limit: 30);
      if (!mounted) return;
      final unread = page.items.where((n) => !n.isRead).length;
      setState(() => _unreadNotificationCount = unread);
    } catch (_) {
      // Fall back to 0 on error.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(_kSearchDebounce, () => _performSearch(value.trim()));
  }

  void _updateSearchDropdownPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final dropdownTop = position.dy + renderBox.size.height;
        if (_searchDropdownTop != dropdownTop) {
          setState(() => _searchDropdownTop = dropdownTop);
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await PlayerVenuesService.instance.browseVenues(
        query: query,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _showSearchResults = true;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _showSearchResults = true;
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
      _isSearching = false;
    });
  }

  void _dismissSearchOverlay() {
    _searchFocusNode.unfocus();
    setState(() => _showSearchResults = false);
  }

  void _onVenueTap(Map<String, dynamic> venue) {
    _clearSearch();
    Navigator.pushNamed(context, '/venue-detail', arguments: venue);
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
    final int notificationCount = _unreadNotificationCount;

    final Map<String, dynamic>? upcomingBooking =
        _upcomingBookings.isNotEmpty ? _upcomingBookings.first : null;

    if (_showSearchResults) {
      _updateSearchDropdownPosition();
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (_showSearchResults) _dismissSearchOverlay();
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  // ── Email nudge banner ──────────────────────────────────────
                  if (!isVerified)
                    const SliverToBoxAdapter(child: _EmailNudgeBanner()),

                  // ── Greeting header ─────────────────────────────────────────
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
                                child: ClipOval(
                                  child: avatarUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: avatarUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          placeholder: (ctx, url) => Icon(
                                            Icons.person_outline,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                          errorWidget: (ctx, url, err) => Icon(
                                            Icons.person_outline,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_outline,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                ),
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
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
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

                  // ── Reliability warning ─────────────────────────────────────
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
                          borderRadius: BorderRadius.circular(AppRadius.md),
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

                  // ── Search field ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _searchFieldKey,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                        0,
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onTap: _updateSearchDropdownPosition,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search venues...',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 18,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Popular Venues section ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: 'Popular Venues',
                            onAction: () =>
                                Navigator.pushNamed(context, '/venues'),
                          ),
                          const SizedBox(height: AppSpacing.xs2),
                          _SectionBody(
                            isLoading: _isLoadingFutsals,
                            error: _futsalsError,
                            onRetry: _loadTopFutsals,
                            placeholderHeight: _kVenueCardHeight,
                            builder: (context) => _topFutsals.isEmpty
                                ? _SectionPlaceholder(
                                    height: _kVenueCardHeight,
                                    child: Text(
                                      'No venues available',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: _kVenueCardHeight,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      itemCount:
                                          math.min(4, _topFutsals.length),
                                      itemBuilder: (ctx, i) =>
                                          _TopFutsalCard(_topFutsals[i]),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Join a Match section ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: 'Join a Match',
                            onAction: () =>
                                Navigator.pushNamed(context, '/discovery'),
                          ),
                          const SizedBox(height: AppSpacing.xs2),
                          _SectionBody(
                            isLoading: _isLoadingTonightMatches,
                            error: _tonightMatchesError,
                            onRetry: _loadTonightMatches,
                            placeholderHeight: _kMatchCardHeight,
                            builder: (context) => _tonightMatches.isEmpty
                                ? _SectionPlaceholder(
                                    height: _kMatchCardHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context, '/discovery'),
                                          child: const Text('Browse All'),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    height: _kMatchCardHeight,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      itemCount:
                                          math.min(5, _tonightMatches.length),
                                      itemBuilder: (ctx, i) =>
                                          _MatchMiniCard(_tonightMatches[i]),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Upcoming Booking section ────────────────────────────────
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
                            onAction: () =>
                                Navigator.pushNamed(context, '/bookings'),
                          ),
                          const SizedBox(height: AppSpacing.xs2),
                          _SectionBody(
                            isLoading: _isLoadingBookings,
                            placeholderHeight: 90,
                            builder: (context) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: upcomingBooking != null
                                  ? _UpcomingBookingCard(upcomingBooking)
                                  : EmptyState(
                                      icon: Icons.sports_soccer_outlined,
                                      title: 'No upcoming bookings',
                                      subtitle:
                                          'Find a court and book your next game',
                                      buttonLabel: 'Browse Courts',
                                      onButton: () => Navigator.pushNamed(
                                          context, '/venues'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search results overlay ──────────────────────────────────────
            if (_showSearchResults)
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                top: _searchDropdownTop - MediaQuery.of(context).padding.top,
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: _kSearchDropdownMaxHeight,
                    ),
                    child: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: _SmallSpinner()),
                          )
                        : _searchResults.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  'No venues found',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs),
                                itemCount: _searchResults.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: AppSpacing.sm,
                                  endIndent: AppSpacing.sm,
                                ),
                                itemBuilder: (context, index) {
                                  final venue = _searchResults[index];
                                  return ListTile(
                                    dense: true,
                                    leading: venue['coverUrl'] != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(AppSpacing.xxs),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  venue['coverUrl'] as String,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                width: 40,
                                                height: 40,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.08),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                width: 40,
                                                height: 40,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.08),
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 20,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.sports_soccer,
                                            color: colorScheme.primary,
                                          ),
                                    title: Text(
                                      venue['name']?.toString() ?? 'Unknown',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: venue['rating'] != null
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: AppColors.warning,
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.xxs),
                                              Text(
                                                '${venue['rating']}',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onTap: () => _onVenueTap(venue),
                                  );
                                },
                              ),
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
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(child: child),
      ),
    );
  }
}
