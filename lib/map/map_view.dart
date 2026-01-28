import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/permisson/permission_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  final TextEditingController _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(mapViewModelProvider.notifier).searchLocation(query);
    });
  }

  void _onResultSelected(Map<String, dynamic> result) {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .selectSearchResult(result);
    if (location != null) {
      _animatedMapController.animateTo(dest: location, zoom: 15);
      _textController.text = result['display_name'];
    }
    FocusScope.of(context).unfocus();
  }

  void _goToCurrentPosition() {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .goToCurrentPosition();
    if (location != null) {
      _animatedMapController.animateTo(dest: location, zoom: 15);
    }
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
    if (!hasGesture) return;
    ref
        .read(mapViewModelProvider.notifier)
        .onMapMove(camera.center.latitude, camera.center.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);

    // İzinler kontrol ediliyor
    if (mapState.isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // İzin verilmemiş
    if (!mapState.hasPermission) {
      return const PermissionView();
    }

    final currentPosition = mapState.currentPosition;
    final initialCenter = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : LatLng(37.7827875, 29.0966476);

    return Scaffold(
      appBar: AppBar(title: const Text('Harita')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _animatedMapController.mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15,
                    onPositionChanged: _onMapMove,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.emindundar.maptracking',
                    ),
                    if (currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              currentPosition.latitude,
                              currentPosition.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          // Arama sonucu eklenen marker'lar
                          ...mapState.markers.map(
                            (location) => Marker(
                              point: location,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
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
          Positioned(
            top: 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black12),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Konum ara...",
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            ref
                                .read(mapViewModelProvider.notifier)
                                .clearSearchResults();
                          },
                        ),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(15),
                      ),
                    ),
                  ),
                ),
                if (mapState.searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: mapState.searchResults.length,
                      itemBuilder: (context, index) {
                        final result = mapState.searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          title: Text(
                            result['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _onResultSelected(result),
                        );
                      },
                    ),
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
          if (!mapState.isAtCurrentPosition)
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
