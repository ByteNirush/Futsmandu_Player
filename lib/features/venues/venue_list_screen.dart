import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/design_system/app_shadows.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import 'presentation/providers/venues_controller.dart';
import 'venues_map_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

enum _ViewMode { list, map }

const _kFilters = [
  'All',
  'Near me',
  'Verified',
  'Turf',
  'Indoor',
  '5v5',
  '7v7'
];

const _kSortOptions = [
  (label: 'Recommended', icon: Icons.stars_rounded),
  (label: 'Rating', icon: Icons.star_border_rounded),
  (label: 'Price: Low to High', icon: Icons.arrow_downward_rounded),
  (label: 'Price: High to Low', icon: Icons.arrow_upward_rounded),
  (label: 'Distance', icon: Icons.near_me_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  final ScrollController _scrollController = ScrollController();

  String _activeFilter = 'All';
  String _activeSort = 'Recommended';
  _ViewMode _viewMode = _ViewMode.list;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Unchanged business logic ───────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      ref.read(venueDiscoveryControllerProvider.notifier).loadMore();
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> venues) {
    return venues.where((v) {
      switch (_activeFilter) {
        case 'All':
          return true;
        case 'Near Me':
          return true;
        case 'Verified':
          return v['isVerified'] == true;
        default:
          if (['5v5', '7v7', 'Turf', 'Indoor'].contains(_activeFilter)) {
            return (v['courts'] as List? ?? []).any(
              (c) =>
                  c['type'] == _activeFilter || c['surface'] == _activeFilter,
            );
          }
          return true;
      }
    }).toList();
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _openFilterSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (_) => _FilterSheet(
        activeFilter: _activeFilter,
        activeSort: _activeSort,
        onApply: (filter, sort) => setState(() {
          _activeFilter = filter;
          _activeSort = sort;
        }),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venueDiscoveryControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (venuesAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final discovery = venuesAsync.value ?? VenueDiscoveryState.initial();
    final filtered = _applyFilter(discovery.items);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: _buildAppBar(colorScheme, textTheme),
      body: Column(
        children: [
          _FilterBar(
            activeFilter: _activeFilter,
            onFilterTap: (f) => setState(() => _activeFilter = f),
            onFiltersBtnTap: _openFilterSheet,
          ),
          Expanded(
            child: _viewMode == _ViewMode.list
                ? _buildList(context, filtered, colorScheme, textTheme)
                : VenuesMapView(
                    venues: filtered,
                    mediaPaddingBottom: MediaQuery.of(context).padding.bottom,
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      titleSpacing: AppSpacing.pageHorizontal,
      toolbarHeight: 60,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Find a court',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: AppFontWeights.bold,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            'Kathmandu',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        _ViewToggle(
          current: _viewMode,
          onChanged: (m) => setState(() => _viewMode = m),
        ),
        const SizedBox(width: AppSpacing.pageHorizontal),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> filtered,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Results count + sort label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xl,
              AppSpacing.pageHorizontal,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '${filtered.length} courts found',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openFilterSheet,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _activeSort,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: AppFontWeights.semiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // List or empty
        if (filtered.isEmpty)
          _EmptySliver(textTheme: textTheme, colorScheme: colorScheme)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.sm,
              AppSpacing.pageHorizontal,
              kNavBarHeight + AppSpacing.xxxl,
            ),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xl),
              itemBuilder: (ctx, i) => VenueCard(venue: filtered[i]),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySliver extends StatelessWidget {
  const _EmptySliver({
    required this.textTheme,
    required this.colorScheme,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: EmptyStateWidget(
          type: EmptyStateType.noSearchResults,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View-mode toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.current, required this.onChanged});

  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.format_list_bulleted_rounded,
            selected: current == _ViewMode.list,
            onTap: () => onChanged(_ViewMode.list),
          ),
          _ToggleBtn(
            icon: Icons.map_outlined,
            selected: current == _ViewMode.map,
            onTap: () => onChanged(_ViewMode.map),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm - 1),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? colorScheme.surface : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activeFilter,
    required this.onFilterTap,
    required this.onFiltersBtnTap,
  });

  final String activeFilter;
  final ValueChanged<String> onFilterTap;
  final VoidCallback onFiltersBtnTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: (56 - _kChipHeight) / 2,
              ),
              children: [
                _FilterChip(
                  label: 'Filters',
                  icon: Icons.tune_rounded,
                  selected: false,
                  onTap: onFiltersBtnTap,
                ),
                ...List.generate(_kFilters.length, (i) {
                  final f = _kFilters[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: _FilterChip(
                      label: f,
                      selected: activeFilter == f,
                      onTap: () => onFilterTap(f),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const double _kChipHeight = 32;

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _kChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected
                    ? colorScheme.surface
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.surface
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? AppFontWeights.semiBold : AppFontWeights.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter / sort bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.activeFilter,
    required this.activeSort,
    required this.onApply,
  });

  final String activeFilter;
  final String activeSort;
  final void Function(String filter, String sort) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _filter;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _filter = widget.activeFilter;
    _sort = widget.activeSort;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
              ),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort & filter',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = 'All';
                    _sort = 'Recommended';
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          // Scrollable body
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const _SheetSectionLabel(title: 'Sort by'),
                const SizedBox(height: AppSpacing.lg),
                ..._kSortOptions.map((opt) => _SortTile(
                      icon: opt.icon,
                      label: opt.label,
                      selected: _sort == opt.label,
                      onTap: () => setState(() => _sort = opt.label),
                    )),
                const SizedBox(height: AppSpacing.xxxl),
                const _SheetSectionLabel(title: 'Court type'),
                const SizedBox(height: AppSpacing.lg),
                _OptionChipGroup(
                  options: const ['Turf', 'Indoor'],
                  active: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _SheetSectionLabel(title: 'Court size'),
                const SizedBox(height: AppSpacing.lg),
                _OptionChipGroup(
                  options: const ['5v5', '7v7'],
                  active: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              bottomInset + AppSpacing.xxl,
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_filter, _sort);
                  Navigator.pop(context);
                },
                child: const Text('Show results'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppFontWeights.bold,
            letterSpacing: 0.1,
          ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
            color: selected
                ? colorScheme.onSurface.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? AppFontWeights.semiBold : AppFontWeights.regular,
                    color: selected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onSurface,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: colorScheme.surface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChipGroup extends StatelessWidget {
  const _OptionChipGroup({
    required this.options,
    required this.active,
    required this.onSelect,
  });

  final List<String> options;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((opt) {
        final selected = active == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: selected ? 1.5 : 1,
              ),
              color: selected ? colorScheme.onSurface : Colors.transparent,
            ),
            child: Text(
              opt,
              style: textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.surface
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? AppFontWeights.semiBold : AppFontWeights.medium,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Venue card (public — reusable elsewhere)
// ─────────────────────────────────────────────────────────────────────────────

class VenueCard extends StatelessWidget {
  const VenueCard({super.key, required this.venue});

  final Map<String, dynamic> venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
    final courts = (venue['courts'] as List? ?? []);
    final verified = venue['isVerified'] == true;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: AppShadows.card(colorScheme),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/venue-detail',
            arguments: venue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VenueCardImage(
                imageUrl: venue['coverUrl'] as String? ?? '',
                rating: rating,
                verified: verified,
              ),
              _VenueCardBody(
                venue: venue,
                courts: courts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image ─────────────────────────────────────────────────────────────────────

class _VenueCardImage extends StatelessWidget {
  const _VenueCardImage({
    required this.imageUrl,
    required this.rating,
    required this.verified,
  });

  final String imageUrl;
  final double rating;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 172,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover photo
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.sports_soccer_rounded,
                  size: AppSpacing.xxl,
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: AppSpacing.xxl,
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
          ),

          // Top gradient for badge contrast
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  colorScheme.scrim.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Rating pill — top right
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _BadgePill(
              color: colorScheme.scrim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.ratingStar,
                    size: 13,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    rating.toStringAsFixed(1),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Verified pill — top left
          if (verified)
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              child: _BadgePill(
                color: AppColors.primary,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Verified',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: AppFontWeights.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: child,
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _VenueCardBody extends StatelessWidget {
  const _VenueCardBody({
    required this.venue,
    required this.courts,
  });

  final Map<String, dynamic> venue;
  final List courts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            venue['name'] as String? ?? '',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeights.bold,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.xs + 1),

          // Address
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  venue['address'] as String? ?? '',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Court type tags — only if present
          if (courts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs + 2,
              runSpacing: AppSpacing.xs + 2,
              children: courts.take(3).map<Widget>((c) {
                final label = (c['type'] ?? c['surface'] ?? '') as String;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  ),
                  child: Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
