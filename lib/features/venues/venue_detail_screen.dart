import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
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

  static const double _spaceXs = 4;
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

  final Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking,
    'Changing Room': Icons.checkroom_outlined,
    'Floodlights': Icons.highlight_outlined,
    'Cafeteria': Icons.restaurant_outlined,
  };

  @override
  void initState() {
    super.initState();
    _detailScrollController.addListener(_onDetailScroll);
  }

  @override
  void dispose() {
    _detailScrollController
      ..removeListener(_onDetailScroll)
      ..dispose();
    super.dispose();
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
                  Text('Write Review', style: AppText.h3),
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
                      Text('Your rating', style: AppText.bodySm),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$rating/5 - ${ratingLabels[rating - 1]}',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      'Tap a star to rate your experience',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.txtDisabled,
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
                  style: AppText.body.copyWith(color: AppColors.txtDisabled),
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
              background: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: venue['coverUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.scrim.withValues(alpha: 0.06),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
                        ],
                        stops: const [0.32, 1.0],
                      ),
                    ),
                  ),
                ],
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
                  const SizedBox(height: _spaceSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: _spaceSm),
                      Expanded(
                        child: Text(
                          venue['address'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                            Icon(Icons.place_rounded,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: _spaceSm),
                            Expanded(
                              child: Text(
                                venue['address'] ?? '',
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        if (venue['latitude'] != null &&
                            venue['longitude'] != null) ...[
                          const SizedBox(height: _spaceSm),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Maps integration coming soon')),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined,
                                    size: 15, color: colorScheme.primary),
                                const SizedBox(width: _spaceXs),
                                Text(
                                  'View on map',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
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
                                _amenityIcons[amenity] ?? Icons.circle,
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
