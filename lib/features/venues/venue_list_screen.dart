import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import 'venues_map_view.dart';

enum _VenueViewMode { list, map }

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  String _search = '';
  String _activeFilter = 'All';
  _VenueViewMode _viewMode = _VenueViewMode.list;

  List<Map<String, dynamic>> get _filtered {
    return MockData.venues.where((v) {
      if (_search.isNotEmpty) {
        final nameMatches =
            (v['name'] as String).toLowerCase().contains(_search.toLowerCase());
        if (!nameMatches) return false;
      }

      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Near Me') return true; // simplified logic
      if (_activeFilter == 'Verified') return v['isVerified'] == true;

      // Filter by Court characteristics
      if (['5v5', '7v7', 'Turf', 'Indoor'].contains(_activeFilter)) {
        return (v['courts'] as List).any(
            (c) => c['type'] == _activeFilter || c['surface'] == _activeFilter);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalCourts = filtered.fold<int>(
      0,
      (sum, venue) => sum + ((venue['courts'] as List?)?.length ?? 0),
    );
    final avgRating = filtered.isEmpty
        ? 0.0
        : filtered.fold<double>(
              0.0,
              (sum, venue) =>
                  sum + ((venue['rating'] as num?)?.toDouble() ?? 0.0),
            ) /
            filtered.length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.xs2,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('Find a Court', style: AppText.h2),
                  ),
                  SegmentedButton<_VenueViewMode>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs3,
                        vertical: AppSpacing.xs,
                      ),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: _viewMode == _VenueViewMode.list
                ? _buildListBody(context, filtered, totalCourts, avgRating)
                : _buildMapBody(context, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody(
      BuildContext context, List<Map<String, dynamic>> filtered) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2),
            child: VenuesMapView(
              venues: filtered,
              mediaPaddingBottom: bottomInset,
            ),
          ),
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              color: AppColors.bgElevated,
              child: _SearchPanel(
                onSearchChanged: (value) => setState(() => _search = value),
              ),
            ),
          ),
          Positioned(
            top: 76,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgPrimary.withValues(alpha: 0.92),
                    AppColors.bgPrimary.withValues(alpha: 0),
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
    int totalCourts,
    double avgRating,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.borderClr.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.explore_rounded,
                        color: AppColors.green, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Discover top futsal venues near you',
                      style: AppText.body.copyWith(
                        color: AppColors.txtPrimary,
                        fontWeight: AppTextStyles.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
            child: _SearchPanel(
              onSearchChanged: (value) => setState(() => _search = value),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    title: 'Venues',
                    value: filtered.length.toString(),
                    icon: Icons.stadium_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    title: 'Courts',
                    value: totalCourts.toString(),
                    icon: Icons.grid_view_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    title: 'Avg Rating',
                    value: avgRating == 0 ? '--' : avgRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs2,
            ),
            child: Text(
              'Browse by preference',
              style: AppText.h3.copyWith(
                fontSize: 18,
                fontWeight: AppTextStyles.semiBold,
                color: AppColors.txtPrimary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs2),
            child: Row(
              children: [
                Text(
                  '${filtered.length} results',
                  style:
                      AppText.body.copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                const Spacer(),
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.txtDisabled,
                ),
                const SizedBox(width: 6),
                Text(
                  'Smart sorted',
                  style: AppText.label.copyWith(
                    color: AppColors.txtDisabled,
                    fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 54,
                      color: AppColors.txtDisabled.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No venues found',
                      style: AppText.h3.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try changing your search or filter to discover more courts.',
                      style:
                          AppText.bodySm.copyWith(color: AppColors.txtDisabled),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (filtered.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.of(context).padding.bottom + kNavBarHeight + 24,
            ),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _VenueCard(venue: filtered[i]),
              ),
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
    final reviewCount = (venue['reviewCount'] as num?)?.toInt() ?? 0;
    final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
    final amenities =
        (venue['amenities'] as List?)?.cast<String>() ?? const <String>[];

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/venue-detail', arguments: venue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.borderClr.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: venue['coverUrl'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) =>
                          Container(color: AppColors.bgSurface),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.bgSurface),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.60),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Pill(
                        icon: venue['isVerified'] == true
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        label: venue['isVerified'] == true
                            ? 'Verified'
                            : 'Standard',
                        bg: venue['isVerified'] == true
                            ? AppColors.green.withValues(alpha: 0.95)
                            : Colors.black.withValues(alpha: 0.55),
                        fg: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              venue['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 18,
                                fontWeight: AppTextStyles.semiBold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                            icon: Icons.location_on_rounded,
                            label: venue['distance'] ?? '',
                            bg: Colors.black.withValues(alpha: 0.55),
                            fg: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue['address'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.txtDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: AppColors.ratingStar),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppText.body
                              .copyWith(fontWeight: AppTextStyles.semiBold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount reviews)',
                          style: AppText.bodySm
                              .copyWith(color: AppColors.txtDisabled),
                        ),
                        const Spacer(),
                        Icon(Icons.sports_soccer_rounded,
                            size: 16, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${(venue['courts'] as List?)?.length ?? 0} courts',
                          style: AppText.label.copyWith(
                            color: AppColors.txtPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: amenities
                          .take(3)
                          .map(
                            (a) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs3,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.borderClr
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              child: Text(
                                a,
                                style: AppText.label.copyWith(
                                  color: AppColors.txtPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.event_available_rounded,
                            text: '$_availableSlots slots available',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.local_offer_rounded,
                            text: _lowestPrice > 0
                                ? 'Rs $_lowestPrice/hr'
                                : 'Unavailable',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs2,
                        vertical: AppSpacing.xs2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 18, color: AppColors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to view details and book your slot',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.green,
                                fontWeight: AppTextStyles.semiBold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.green,
                          ),
                        ],
                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderClr.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: AppText.bodySm,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.txtDisabled),
          suffixIcon: Icon(Icons.filter_alt_rounded,
              color: AppColors.txtDisabled, size: 20),
          hintText: 'Search by venue name',
          hintStyle: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs2),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderClr.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.body.copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: AppColors.txtDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs3,
        vertical: AppSpacing.xs3,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(
                color: AppColors.txtPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: AppTextStyles.semiBold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
