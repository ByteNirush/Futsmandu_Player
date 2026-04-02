import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen Google Map with a sample marker and optional custom JSON style.
///
/// **API keys (required):**
/// - Android: `android/app/src/main/AndroidManifest.xml` → `com.google.android.geo.API_KEY`
/// - iOS: `ios/Runner/AppDelegate.swift` → `GMSServices.provideAPIKey(...)`
///
/// Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud Console
/// for the same or separate keys.
class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  /// Initial region (Kathmandu area — adjust for your venues).
  static const CameraPosition _kInitial = CameraPosition(
    target: LatLng(27.684650811368293, 85.31695516277365),
    zoom: 16,
  );

  /// Secondary camera (demo animation target).
  static const CameraPosition _kDemo = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  static const LatLng _markerPcs = LatLng(27.68506982015234, 85.31687928223276);

  String? _mapStyleJson;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadMapStyles();
  }

  Future<void> _loadMapStyles() async {
    try {
      final json = await rootBundle.loadString('assets/raw/maptheme.json');
      if (!mounted) return;
      setState(() => _mapStyleJson = json.trim().isEmpty ? null : json);
    } catch (_) {
      // Missing asset or invalid file — use default map styling.
      if (!mounted) return;
      setState(() => _mapStyleJson = null);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted && mounted) {
      await [
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  Future<void> _openPlaceInGoogleMaps(LatLng position) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _goToDemoCamera() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kDemo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: GoogleMap(
        style: _mapStyleJson,
        initialCameraPosition: _kInitial,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapToolbarEnabled: true,
        compassEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
        markers: {
          Marker(
            markerId: const MarkerId('PCPS'),
            position: _markerPcs,
            infoWindow: const InfoWindow(
              title: 'PCPS College',
              snippet: 'pcps.edu.np — tap marker to open in Maps',
            ),
            onTap: () => _openPlaceInGoogleMaps(_markerPcs),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToDemoCamera,
        label: const Text('Demo camera'),
        icon: const Icon(Icons.explore),
      ),
    );
  }
}
