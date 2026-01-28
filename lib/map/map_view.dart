import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:maptracking/permisson/permission_service.dart';
import 'package:maptracking/permisson/permission_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  bool _hasPermission = false;
  bool _isChecking = true;
  Position? _currentPosition;
  bool _isAtCurrentPosition = true;

  late final AnimatedMapController _animatedMapController;
  final TextEditingController _textController = TextEditingController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _checkPermission();
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _textController.text;
    if (query.isEmpty) return;
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.emindundar.maptracking'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'];

          final searchedLocation = LatLng(lat, lon);
          _animatedMapController.animateTo(dest: searchedLocation, zoom: 15);
          setState(() {
            _markers.add(
              Marker(
                point: searchedLocation,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on),
              ),
            );
          });
        }
        _animatedMapController.animateTo(
          dest: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 15,
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error:200 dönmedi $e");
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await PermissionService.requestLocationPermission();

    if (!mounted) return;

    final checkHasPermission =
        status == LocationPermission.whileInUse ||
        status == LocationPermission.always;

    if (checkHasPermission) {
      await _getCurrentPosition();
    }

    setState(() {
      _hasPermission = checkHasPermission;
      _isChecking = false;
    });
  }

  Future<void> _getCurrentPosition() async {
    final position = await PermissionService.getUserCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
    });
  }

  void _onPermissionGranted() {
    _getCurrentPosition();
    setState(() {
      _hasPermission = true;
      _isChecking = false;
    });
  }

  void _goToCurrentPosition() {
    if (_currentPosition == null) return;
    _animatedMapController.animateTo(
      dest: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      zoom: 15,
    );
    setState(() {
      _isAtCurrentPosition = true;
    });
  }

  void _zoomIn() {
    final currentZoom = _animatedMapController.mapController.camera.zoom;
    _animatedMapController.animatedZoomTo(currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _animatedMapController.mapController.camera.zoom;
    _animatedMapController.animatedZoomTo(currentZoom - 1);
  }

  void _onMapMove(MapCamera camera, bool hasGesture) {
    if (!hasGesture || _currentPosition == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    const tolerance = 0.005;
    final isNear =
        (camera.center.latitude - currentLatLng.latitude).abs() < tolerance &&
        (camera.center.longitude - currentLatLng.longitude).abs() < tolerance;

    if (_isAtCurrentPosition != isNear) {
      setState(() {
        _isAtCurrentPosition = isNear;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return PermissionView(onPermissionGranted: _onPermissionGranted);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Harita')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                hintText: 'Konum ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : LatLng(37.7827875, 29.0966476),
                initialZoom: 15,
                onPositionChanged: _onMapMove,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.emindundar.maptracking',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                const Scalebar(),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            mini: true,
            onPressed: _zoomIn,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            mini: true,
            onPressed: _zoomOut,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          if (!_isAtCurrentPosition)
            FloatingActionButton(
              heroTag: 'myLocation',
              onPressed: _goToCurrentPosition,
              child: const Icon(Icons.my_location),
            ),
        ],
      ),
    );
  }
}
