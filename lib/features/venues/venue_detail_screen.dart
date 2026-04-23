import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/futs_button.dart';
import 'data/services/player_venues_service.dart';

class _VenueDetailSpacing {
  // Keep these aligned with the screen's local `_space*` scale.
  static const EdgeInsets pillPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xs2,
    vertical: AppSpacing.xs,
  );
  static const double sectionHeaderGap = AppSpacing.xs2; // 12
  static const double sectionGap = AppSpacing.lg; // 16
  static const double smallGap = AppSpacing.xxs; // 4
  static const EdgeInsets reviewCardPadding = EdgeInsets.all(AppSpacing.xs2);
}

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final PlayerVenuesService _venuesService = PlayerVenuesService.instance;
  final ScrollController _detailScrollController = ScrollController();
  late final PageController _pageController;

  static const double _spaceSm = 8;
  static const double _spaceMd = 12;
  static const double _spaceLg = 16;
  static const double _spaceXl = 20;
  static const double _space2xl = 24;

  String? _venueId;
  Map<String, dynamic>? _venue;
  bool _isLoading = true;
  String? _errorMessage;

  int _courtIdx = 0;
  bool _showCollapsedTitle = false;
  int _currentImagePage = 0;

  final Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking_rounded,
    'Changing Room': Icons.checkroom_outlined,
    'Floodlights': Icons.highlight_outlined,
    'Cafeteria': Icons.restaurant_outlined,
    'Wifi': Icons.wifi_rounded,
    'Restroom': Icons.wc_outlined,
    'Shower': Icons.shower_outlined,
    'Seating': Icons.chair_rounded,
    'Lights': Icons.light_rounded,
    'Equipment': Icons.sports_rounded,
    'Water': Icons.water_drop_outlined,
  };

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('food') || lower.contains('cafe') || lower.contains('restaurant')) return Icons.restaurant_rounded;
    if (lower.contains('seating') || lower.contains('lounge')) return Icons.chair_rounded;
    if (lower.contains('light') || lower.contains('flood')) return Icons.light_rounded;
    if (lower.contains('shoe') || lower.contains('equipment')) return Icons.sports_rounded;
    if (lower.contains('water') || lower.contains('drink')) return Icons.water_drop_outlined;
    if (lower.contains('restroom') || lower.contains('toilet') || lower.contains('changing')) return Icons.wc_outlined;
    if (lower.contains('shower')) return Icons.shower_outlined;
    return _amenityIcons[amenity] ?? Icons.check_circle_rounded;
  }

  @override
  void initState() {
    super.initState();
    _detailScrollController.addListener(_onDetailScroll);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _detailScrollController
      ..removeListener(_onDetailScroll)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Get list of images for carousel: cover image + any gallery images
  List<String> get _carouselImages {
    final images = <String>[];
    final coverUrl = _venue?['coverUrl'] as String?;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      images.add(coverUrl);
    }
    // Add gallery images if available (from API)
    final galleryUrls = _venue?['galleryUrls'] as List<dynamic>?;
    if (galleryUrls != null) {
      for (final url in galleryUrls) {
        if (url is String && url.isNotEmpty && !images.contains(url)) {
          images.add(url);
        }
      }
    }
    return images;
  }

  void _onDetailScroll() {
    if (!_detailScrollController.hasClients) return;
    final showTitle = _detailScrollController.offset > 170;
    if (showTitle != _showCollapsedTitle && mounted) {
      setState(() => _showCollapsedTitle = showTitle);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_venueId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _venueId = args['id'] as String?;
      _venue = args;
      if (_venueId != null && _venueId!.isNotEmpty) {
        _loadVenueDetail();
        return;
      }
    }

    _isLoading = false;
    _errorMessage = 'Venue ID is missing.';
  }

  Future<void> _loadVenueDetail() async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final venue = await _venuesService.getVenueDetail(venueId);
      if (!mounted) return;
      setState(() {
        _venue = venue;
        _isLoading = false;
        if (_courtIdx >= (_venue?['courts'] as List? ?? const []).length) {
          _courtIdx = 0;
        }
      });
    } on VenueApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load venue details right now.';
      });
    }
  }

  Future<void> _showWriteReviewSheet() async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    final bookingIdController = TextEditingController();
    final commentController = TextEditingController();
    int rating = 5;
    const ratingLabels = <String>[
      'Poor',
      'Fair',
      'Good',
      'Very Good',
      'Excellent',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetColorScheme = Theme.of(sheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write Review',
                    style: AppTypography.subHeading(context, sheetColorScheme),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: bookingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Booking ID',
                      hintText: 'Enter completed booking ID',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Your rating',
                        style: AppTypography.caption(context, sheetColorScheme),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$rating/5 - ${ratingLabels[rating - 1]}',
                        style: AppTypography.caption(context, sheetColorScheme)
                            .copyWith(
                              color: AppColors.warning,
                              fontWeight: AppFontWeights.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      'Tap a star to rate your experience',
                      style: AppTypography.caption(
                        context,
                        sheetColorScheme,
                        color: sheetColorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= rating;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () =>
                                setSheetState(() => rating = starValue),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxs),
                              child: Icon(
                                isSelected
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 32,
                                color: isSelected
                                    ? AppColors.warning
                                    : AppColors.txtDisabled,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final bookingId = bookingIdController.text.trim();
                        if (bookingId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Booking ID is required')),
                          );
                          return;
                        }

                        try {
                          await _venuesService.createVenueReview(
                            venueId: venueId,
                            bookingId: bookingId,
                            rating: rating,
                            comment: commentController.text,
                          );
                          if (!mounted) return;
                          Navigator.of(this.context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Review submitted successfully')),
                          );
                          _loadVenueDetail();
                        } on VenueApiException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not submit review')),
                          );
                        }
                      },
                      child: const Text('Submit Review'),
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

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading && _venue == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _venue == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Venue'),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage ?? 'Could not load venue details.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    context,
                    Theme.of(context).colorScheme,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _loadVenueDetail,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final venue = _venue;
    if (venue == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Venue'),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: const Center(child: Text('Venue not found')),
      );
    }

    final courts = (venue['courts'] as List?) ?? const [];
    if (courts.isEmpty) {
      _courtIdx = 0;
    }

    final isVerified = venue['isVerified'] == true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                padding: const EdgeInsets.fromLTRB(
                    _spaceLg, _spaceMd, _spaceLg, _spaceMd),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: FutsButton(
                  label: 'Book Now',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/book-court',
                    arguments: {
                      ...venue,
                      'initialCourtIdx': _courtIdx,
                    },
                  ),
                ),
              );
            },
          ),
        ),
      body: CustomScrollView(
        controller: _detailScrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _showCollapsedTitle ? 1 : 0,
              child: Text(
                venue['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _VenueCoverCarousel(
                imageUrls: _carouselImages,
                venueName: venue['name'] ?? '',
                isVerified: isVerified,
                pageController: _pageController,
                currentPage: _currentImagePage,
                onPageChanged: (page) => setState(() => _currentImagePage = page),
              ),
            ),
            actions: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.62),
                ),
                icon: Icon(Icons.share, color: colorScheme.onSurface),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                _spaceLg,
                AppSpacing.pagePadding,
                _space2xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] ?? '',
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      if (isVerified)
                        Icon(
                          Icons.verified_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: _spaceMd),
                  Wrap(
                    spacing: _spaceSm,
                    runSpacing: _spaceSm,
                    children: [
                      _MetaPill(
                        icon: isVerified
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        label: isVerified ? 'Verified Venue' : 'Standard Venue',
                      ),
                      _MetaPill(
                        icon: Icons.star_rounded,
                        label: '${venue['rating']} (${venue['reviewCount']})',
                      ),
                      _MetaPill(
                        icon: Icons.sports_soccer_rounded,
                        label: '${courts.length} Courts',
                      ),
                      if (venue['distance'] != null)
                        _MetaPill(
                          icon: Icons.near_me_rounded,
                          label: venue['distance'],
                        ),
                    ],
                  ),
                  const SizedBox(height: _spaceXl),

                  if ((venue['description'] as String?)?.isNotEmpty == true)
                    _SectionCard(
                      title: 'About',
                      child: Text(
                        venue['description'] as String,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),

                  _SectionCard(
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 24,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: _spaceMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue['address'] ?? '',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if ((venue['addressCity'] ?? '').isNotEmpty ||
                                      (venue['addressDistrict'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${venue['addressCity'] ?? ''}, ${venue['addressDistrict'] ?? ''}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (venue['latitude'] != null &&
                            venue['longitude'] != null) ...[
                          const SizedBox(height: _spaceMd),
                          Row(
                            children: [
                              Icon(
                                Icons.my_location_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: _spaceSm),
                              Text(
                                'Lat: ${(venue['latitude'] as num).toStringAsFixed(6)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: _spaceLg),
                              Icon(
                                Icons.my_location_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: _spaceSm),
                              Text(
                                'Lng: ${(venue['longitude'] as num).toStringAsFixed(6)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  _SectionCard(
                    title: 'Contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((venue['ownerPhone'] as String?)?.isNotEmpty == true)
                          _ContactRow(
                            icon: Icons.phone_outlined,
                            value: venue['ownerPhone'] as String,
                          )
                        else
                          Text(
                            'Contact details not available.',
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),

                  _SectionCard(
                    title: 'Amenities',
                    child: Wrap(
                      spacing: _spaceSm,
                      runSpacing: _spaceSm,
                      children: (venue['amenities'] as List).map((a) {
                        final amenity = a.toString();
                        return Container(
                          padding: _VenueDetailSpacing.pillPadding,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                amenity,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Reviews
                  const SizedBox(height: _spaceXl),
                  _SectionCard(
                    title: 'Reviews',
                    trailing: TextButton(
                      onPressed: _showWriteReviewSheet,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: _VenueDetailSpacing.pillPadding,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        textStyle: textTheme.labelSmall,
                      ),
                      child: const Text('Write review'),
                    ),
                    child: _buildReviews(venue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(Map<String, dynamic> venue) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reviews = (venue['reviews'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          'No reviews yet. Be the first to review this venue.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: reviews.take(3).toList().asMap().entries.map(
        (entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == reviews.take(3).length - 1 ? 0 : _spaceMd,
            ),
            child: _ReviewCard(entry.value),
          );
        },
      ).toList(),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    return Container(
      padding: _VenueDetailSpacing.pillPadding,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: _VenueDetailSpacing.smallGap),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
        child,
        const SizedBox(height: _VenueDetailSpacing.sectionGap),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> r;

  const _ReviewCard(this.r);

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final String author = (r['author'] as String?) ?? '';
    final String authorInitial = author.isNotEmpty ? author[0] : '?';

    return Container(
      padding: _VenueDetailSpacing.reviewCardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                alignment: Alignment.center,
                child: Text(
                  authorInitial,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (idx) => Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.xxs / 2),
                            child: Icon(
                              idx < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Text(r['date'], style: theme.textTheme.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
          Text(
            r['text'],
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _VenueCoverCarousel
// Swipeable image slider for the venue details hero area.
// • Shows cover image first, then any gallery images.
// • Animated dot indicators + swipe gesture support.
// • Image counter badge when multiple images.
// • Gradient overlay for text readability.
// ============================================================================

class _VenueCoverCarousel extends StatelessWidget {
  const _VenueCoverCarousel({
    required this.imageUrls,
    required this.venueName,
    required this.isVerified,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final String venueName;
  final bool isVerified;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasImages = imageUrls.isNotEmpty;
    final multipleImages = imageUrls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Page view with images ─────────────────────────────────────────
        if (hasImages)
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final url = imageUrls[index];
              return Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          )
        else
          // No images — show placeholder
          Container(
            color: colorScheme.primaryContainer,
            child: Center(
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),

        // ── Gradient overlay ───────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colorScheme.scrim.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ),

        // ── Image counter badge (multi-image only) ─────────────────────────
        if (multipleImages)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${currentPage + 1} / ${imageUrls.length}',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Dot indicators (multi-image only) ─────────────────────────────
        if (multipleImages)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                );
              }),
            ),
          ),

        // ── Left chevron (multi-image only) ────────────────────────────────
        if (multipleImages && currentPage > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // ── Right chevron (multi-image only) ───────────────────────────────
        if (multipleImages && currentPage < imageUrls.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
