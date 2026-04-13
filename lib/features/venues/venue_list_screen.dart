import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import 'presentation/providers/venues_controller.dart';
import 'venues_map_view.dart';

enum _VenueViewMode { list, map }

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  final ScrollController _scrollController = ScrollController();

  String _search = '';
  String _activeFilter = 'All';
  _VenueViewMode _viewMode = _VenueViewMode.list;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(venueDiscoveryControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value.trim());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(venueDiscoveryControllerProvider.notifier).search(_search),
    );
  }

  List<Map<String, dynamic>> _filteredFrom(List<Map<String, dynamic>> venues) {
    return venues.where((v) {
      if (_search.isNotEmpty) {
        final nameMatches =
            (v['name'] as String).toLowerCase().contains(_search.toLowerCase());
        if (!nameMatches) return false;
      }

      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Near Me') return true;
      if (_activeFilter == 'Verified') return v['isVerified'] == true;

      if (['5v5', '7v7', 'Turf', 'Indoor'].contains(_activeFilter)) {
        return (v['courts'] as List).any(
            (c) => c['type'] == _activeFilter || c['surface'] == _activeFilter);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final venuesState = ref.watch(venueDiscoveryControllerProvider);
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;

    if (venuesState.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (venuesState.hasError) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  venuesState.error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => ref
                      .read(venueDiscoveryControllerProvider.notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final discovery = venuesState.value ?? VenueDiscoveryState.initial();
    final filtered = _filteredFrom(discovery.items);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Find a Court', style: theme.textTheme.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: SegmentedButton<_VenueViewMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(
                  value: _VenueViewMode.list,
                  icon: Icon(Icons.view_list_rounded, size: 18),
                  label: Text('List'),
                ),
                ButtonSegment(
                  value: _VenueViewMode.map,
                  icon: Icon(Icons.map_rounded, size: 18),
                  label: Text('Map'),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<_VenueViewMode> next) {
                setState(() => _viewMode = next.first);
              },
            ),
          ),
        ],
      ),
      body: _viewMode == _VenueViewMode.list
          ? _buildListBody(context, filtered)
          : _buildMapBody(context, filtered),
    );
  }

  Widget _buildMapBody(
      BuildContext context, List<Map<String, dynamic>> filtered) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: VenuesMapView(
              venues: filtered,
              mediaPaddingBottom: bottomInset,
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.pagePadding,
            right: AppSpacing.pagePadding,
            child: _SearchPanel(
              onSearchChanged: _onSearchChanged,
            ),
          ),
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0),
                  ],
                ),
              ),
              child: FilterChipRow(
                options: const [
                  'All',
                  'Near Me',
                  'Turf',
                  'Indoor',
                  '5v5',
                  '7v7',
                  'Verified'
                ],
                selected: _activeFilter,
                onSelected: (v) => setState(() => _activeFilter = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    List<Map<String, dynamic>> filtered,
  ) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: _SearchPanel(
              onSearchChanged: _onSearchChanged,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FilterChipRow(
              options: const [
                'All',
                'Near Me',
                'Turf',
                'Indoor',
                '5v5',
                '7v7',
                'Verified'
              ],
              selected: _activeFilter,
              onSelected: (v) => setState(() => _activeFilter = v),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} matches',
                  style: theme.textTheme.headlineSmall,
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: Icon(Icons.sort_rounded,
                      size: 18, color: colorScheme.primary),
                  label: const Text('Sort'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        size: 44,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No courts available',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: AppFontWeights.semiBold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We couldn\'t find any venues matching your current filters. Try adjusting your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              MediaQuery.of(context).padding.bottom +
                  kNavBarHeight +
                  AppSpacing.pagePadding,
            ),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _VenueCard(venue: filtered[i]),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(venueDiscoveryControllerProvider).value;
              if (state == null || !state.isLoadingMore) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _VenueCard({required this.venue});

  int get _lowestPrice {
    final courts = (venue['courts'] as List?) ?? [];
    int? minimum;
    for (final court in courts) {
      final slots = ((court as Map<String, dynamic>)['slots'] as List?) ?? [];
      for (final slot in slots) {
        final price = (slot as Map<String, dynamic>)['price'];
        if (price is int) {
          minimum =
              minimum == null ? price : (price < minimum ? price : minimum);
        }
      }
    }
    return minimum ?? 0;
  }

  int get _availableSlots {
    final courts = (venue['courts'] as List?) ?? [];
    var count = 0;
    for (final court in courts) {
      final slots = ((court as Map<String, dynamic>)['slots'] as List?) ?? [];
      count += slots
          .where(
              (slot) => (slot as Map<String, dynamic>)['status'] == 'AVAILABLE')
          .length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTheme.radiusM);
    final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
    final amenities =
        (venue['amenities'] as List?)?.cast<String>() ?? const <String>[];
    final hasPrice = _lowestPrice > 0;

    return DecoratedBox(
      decoration: isDark
          ? AppTheme.cardDecorationDark(colorScheme)
          : BoxDecoration(
              color: colorScheme.surface,
              borderRadius: radius,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/venue-detail', arguments: venue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 136,
                child: CachedNetworkImage(
                  imageUrl: venue['coverUrl'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: colorScheme.surface),
                  errorWidget: (_, __, ___) => Container(color: colorScheme.surface),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  venue['name'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (venue['isVerified'] == true) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                            color: colorScheme.primary.withValues(alpha: 0.14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                rating.toStringAsFixed(1),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            venue['address'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (venue['distance'] != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            venue['distance'] ?? '',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (amenities.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: amenities.take(3).map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border:
                                  Border.all(color: colorScheme.outlineVariant),
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                            ),
                            child: Text(
                              a,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: AppFontWeights.semiBold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Slots',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '$_availableSlots',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: AppFontWeights.extraBold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 34,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Starts at',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                hasPrice
                                    ? 'NPR $_lowestPrice/hr'
                                    : 'Not Available',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: hasPrice
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
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
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _SearchPanel({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return TextField(
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by venue name...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
