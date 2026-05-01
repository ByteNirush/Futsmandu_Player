import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:futsmandu_design_system/core/theme/app_radius.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../home/home_shell.dart' show kNavBarHeight;

/// Google Map for browsing venues: markers from `lat` / `lng` on each venue map,
/// fit-to-bounds, bottom sheet on marker tap, optional directions in external Maps.
class VenuesMapView extends StatefulWidget {
  const VenuesMapView({
    super.key,
    required this.venues,
    this.mediaPaddingBottom = 0,
  });

  /// Filtered venue list (same logic as the list tab).
  final List<Map<String, dynamic>> venues;

  /// Typically `MediaQuery.of(context).padding.bottom` for safe area.
  final double mediaPaddingBottom;

  @override
  State<VenuesMapView> createState() => _VenuesMapViewState();
}

class _VenuesMapViewState extends State<VenuesMapView> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kFallback = CameraPosition(
    target: LatLng(27.7000, 85.3100),
    zoom: 12,
  );

  String? _mapStyleJson;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadMapStyles();
  }

  @override
  void didUpdateWidget(covariant VenuesMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_venueSignature(oldWidget.venues) != _venueSignature(widget.venues)) {
      _fitAfterMarkersChange();
    }
  }

  String _venueSignature(List<Map<String, dynamic>> list) {
    return list.map((v) => '${v['id']}').join('|');
  }

  Future<void> _loadMapStyles() async {
    try {
      final json = await rootBundle.loadString('assets/raw/maptheme.json');
      if (!mounted) return;
      setState(() => _mapStyleJson =
          json.trim().isEmpty || json.trim() == '[]' ? null : json);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mapStyleJson = null);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted && mounted) {
      await [Permission.location, Permission.locationWhenInUse].request();
    }
  }

  LatLng? _latLngFor(Map<String, dynamic> v) {
    final lat = v['lat'];
    final lng = v['lng'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  Set<Marker> _buildMarkers() {
    final out = <Marker>{};
    for (final v in widget.venues) {
      final pos = _latLngFor(v);
      if (pos == null) continue;
      final id = v['id'] as String? ?? pos.toString();
      final name = v['name'] as String? ?? 'Venue';
      final address = v['address'] as String? ?? '';
      final rating = (v['rating'] as num?)?.toStringAsFixed(1) ?? '';
      out.add(
        Marker(
          markerId: MarkerId(id),
          position: pos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: name,
            snippet: address.isNotEmpty ? '$address · ★ $rating' : '★ $rating',
          ),
          onTap: () => _showVenueSheet(v, pos),
        ),
      );
    }
    return out;
  }

  Future<void> _openDirections(LatLng pos) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showVenueSheet(Map<String, dynamic> venue, LatLng pos) {
    final rating = (venue['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (venue['reviewCount'] as num?)?.toInt() ?? 0;
    final courts = (venue['courts'] as List?)?.length ?? 0;
    final verified = venue['isVerified'] == true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.xs + widget.mediaPaddingBottom + kNavBarHeight,
          ),
          child: Material(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.large,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm2,
                AppSpacing.sm,
                AppSpacing.sm2,
                AppSpacing.sm2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSpacing.xl,
                      height: AppSpacing.xxs,
                      decoration: BoxDecoration(
                        color: AppColors.borderClr,
                        borderRadius: AppRadius.extraLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] as String? ?? '',
                          style: AppTypography.subHeading(context, Theme.of(context).colorScheme),
                        ),
                      ),
                      if (verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: AppRadius.small,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                size: AppSpacing.md - 8, color: AppColors.green),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                'Verified',
                                style: AppTypography.textTheme(
                                  Theme.of(context).colorScheme,
                                ).labelMedium?.copyWith(
                                  color: AppColors.green,
                                  fontWeight: AppFontWeights.semiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined,
                          size: AppSpacing.md - 6, color: AppColors.txtDisabled),
                      const SizedBox(width: AppSpacing.xs2 - 6),
                      Expanded(
                        child: Text(
                          venue['address'] as String? ?? '',
                          style: AppTypography.body(context, Theme.of(ctx).colorScheme)
                              .copyWith(fontSize: 14 * AppTypographyScale.fromContext(ctx))
                              .copyWith(color: AppColors.txtDisabled),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: AppSpacing.md - 4, color: AppColors.ratingStar),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.body(context, Theme.of(ctx).colorScheme)
                            .copyWith(fontWeight: AppFontWeights.semiBold),
                      ),
                      Text(
                        ' ($reviewCount) · $courts courts',
                        style: AppTypography.body(context, Theme.of(ctx).colorScheme)
                            .copyWith(fontSize: 14 * AppTypographyScale.fromContext(ctx))
                            .copyWith(color: AppColors.txtDisabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openDirections(pos);
                          },
                          icon: const Icon(Icons.directions_rounded, size: AppSpacing.md - 4),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.txtPrimary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs2),
                            side: BorderSide(color: AppColors.borderClr),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs2),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/venue-detail',
                                arguments: venue);
                          },
                          icon:
                              const Icon(Icons.sports_soccer_rounded, size: AppSpacing.md - 4),
                          label: const Text('View venue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.bgPrimary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs2),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fitAfterMarkersChange() async {
    if (!_controller.isCompleted) return;
    final c = await _controller.future;
    await _fitBounds(c, widget.venues);
  }

  Future<void> _fitBounds(
    GoogleMapController c,
    List<Map<String, dynamic>> venues,
  ) async {
    final points = <LatLng>[];
    for (final v in venues) {
      final p = _latLngFor(v);
      if (p != null) points.add(p);
    }
    if (points.isEmpty) return;
    if (points.length == 1) {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15),
        ),
      );
      return;
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    final sw = LatLng(minLat, minLng);
    final ne = LatLng(maxLat, maxLng);
    await c.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne), 72));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = widget.mediaPaddingBottom + kNavBarHeight + 8;
    final markers = _buildMarkers();

    if (widget.venues.isEmpty) {
      return Container(
        color: AppColors.bgPrimary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined,
                    size: 88,
                    color: AppColors.txtDisabled.withValues(alpha: 0.7)),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  'No venues on the map',
                  style: AppTypography.subHeading(context, Theme.of(context).colorScheme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Try adjusting search or filters, then switch back to the list.',
                  style: AppTypography.body(context, Theme.of(context).colorScheme)
                    .copyWith(fontSize: 14 * AppTypographyScale.fromContext(context))
                    .copyWith(color: AppColors.txtDisabled),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.large,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            style: _mapStyleJson,
            initialCameraPosition: _kFallback,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(
              top: kNavBarHeight + AppSpacing.sm2,
              bottom: bottomPad,
            ),
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await _fitBounds(controller, widget.venues);
              });
            },
          ),
        ],
      ),
    );
  }
}
