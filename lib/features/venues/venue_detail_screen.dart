import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../shared/widgets/futs_button.dart';
import 'data/services/player_venues_service.dart';

class _VenueDetailSpacing {
  static const double sectionGap = 20;
  static const double subSectionGap = 16;
  static const double smallGap = 6;
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

  static const double _spaceMd = 12;

  String? _venueId;
  Map<String, dynamic>? _venue;
  bool _isLoading = true;
  String? _errorMessage;

  int _courtIdx = 0;
  bool _showCollapsedTitle = false;
  int _currentImagePage = 0;

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
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write Review',
                    style: AppTypography.subHeading(context, sheetColorScheme),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.sm),
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
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= rating;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () =>
                                setSheetState(() => rating = starValue),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _errorMessage ?? 'Could not load venue details.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    context,
                    Theme.of(context).colorScheme,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                    AppSpacing.xl, _spaceMd, AppSpacing.xl, _spaceMd),
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
      body: SingleChildScrollView(
        controller: _detailScrollController,
        child: Column(
          children: [
            // ── Hero Header ──────────────────────────────────────────
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _VenueCoverCarousel(
                    imageUrls: _carouselImages,
                    venueName: venue['name'] ?? '',
                    isVerified: isVerified,
                    pageController: _pageController,
                    currentPage: _currentImagePage,
                    onPageChanged: (page) => setState(() => _currentImagePage = page),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
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
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Unified Content Container ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Venue Name & Rating Row ───────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue['name'] ?? '',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: AppFontWeights.semiBold,
                                ),
                              ),
                              const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${venue['rating']}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: AppFontWeights.semiBold,
                                    ),
                                  ),
                                  Text(
                                    ' · ${venue['reviewCount']} reviews',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 12,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Verified',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: AppFontWeights.semiBold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),

                    // ── Meta Info Chips ────────────────────────────────────────
                    Wrap(
                      spacing: _VenueDetailSpacing.subSectionGap,
                      runSpacing: _VenueDetailSpacing.subSectionGap,
                      children: [
                        _MetaChip(
                          icon: Icons.sports_soccer_rounded,
                          label: '${courts.length} Courts',
                        ),
                        if (venue['distance'] != null)
                          _MetaChip(
                            icon: Icons.near_me_rounded,
                            label: venue['distance'],
                          ),
                      ],
                    ),

                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),

                    // ── About Section ──────────────────────────────────────────
                    if ((venue['description'] as String?)?.isNotEmpty == true) ...[
                      const _SectionHeader(title: 'About'),
                      const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                      Text(
                        venue['description'] as String,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                    ],

                    // ── Location Section ───────────────────────────────────────
                    const _SectionHeader(title: 'Location'),
                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: _VenueDetailSpacing.subSectionGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue['address'] ?? '',
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                              if ((venue['addressCity'] ?? '').isNotEmpty ||
                                  (venue['addressDistrict'] ?? '').isNotEmpty)
                                Text(
                                  '${venue['addressCity'] ?? ''}${(venue['addressCity'] ?? '').isNotEmpty && (venue['addressDistrict'] ?? '').isNotEmpty ? ', ' : ''}${venue['addressDistrict'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _VenueDetailSpacing.sectionGap),

                    // ── Contact Section ────────────────────────────────────────
                    const _SectionHeader(title: 'Contact'),
                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                    if ((venue['ownerPhone'] as String?)?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: _VenueDetailSpacing.subSectionGap),
                          Text(
                            venue['ownerPhone'] as String,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Contact details not available.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: _VenueDetailSpacing.sectionGap),

                    // ── Amenities Section ──────────────────────────────────────
                    const _SectionHeader(title: 'Amenities'),
                    const SizedBox(height: _VenueDetailSpacing.smallGap),
                    Wrap(
                      spacing: _VenueDetailSpacing.subSectionGap,
                      runSpacing: _VenueDetailSpacing.subSectionGap,
                      children: (venue['amenities'] as List).map((a) {
                        final amenity = a.toString();
                        return _AmenityChip(label: amenity);
                      }).toList(),
                    ),
                    const SizedBox(height: _VenueDetailSpacing.sectionGap),

                    // ── Reviews Section ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionHeader(title: 'Reviews'),
                        TextButton.icon(
                          onPressed: _showWriteReviewSheet,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Write a Review'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            textStyle: textTheme.labelMedium?.copyWith(
                              fontWeight: AppFontWeights.semiBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                    _buildReviews(venue),
                    const SizedBox(height: _VenueDetailSpacing.subSectionGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviews(Map<String, dynamic> venue) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reviews = (venue['reviews'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    if (reviews.isEmpty) {
      return Text(
        'No reviews yet. Be the first to review this venue.',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: reviews.take(3).toList().asMap().entries.map(
        (entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == reviews.take(3).length - 1
                  ? 0
                  : _VenueDetailSpacing.subSectionGap,
            ),
            child: _ReviewCard(entry.value),
          );
        },
      ).toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: AppFontWeights.semiBold,
      ),
    );
  }
}






class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> r;

  const _ReviewCard(this.r);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final String author = (r['author'] as String?) ?? '';
    final String authorInitial = author.isNotEmpty ? author[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            authorInitial,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: AppFontWeights.semiBold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      author,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r['date'] ?? '',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Stars and Rating
              Row(
                children: [
                  ...List.generate(
                    5,
                    (idx) => Icon(
                      idx < rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: idx < rating.round()
                          ? AppColors.warning
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rating.toStringAsFixed(1),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Review Text
              Text(
                r['text'] ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: PageView.builder(
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
            ),
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
                      fontWeight: AppFontWeights.semiBold,
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
