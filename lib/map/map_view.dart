import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/permission/permission_view.dart';
import 'package:maptracking/permission/permission_view_model.dart';
import 'package:maptracking/util/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    // Varsayılan olarak mevcut konumu başlangıç olarak ayarla
    _startController.text = AppStrings.currentLocation;
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onStartSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(mapViewModelProvider.notifier)
          .searchLocation(query, SearchField.start);
    });
  }

  void _onDestinationSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(mapViewModelProvider.notifier)
          .searchLocation(query, SearchField.destination);
    });
  }

  void _onStartResultSelected(LocationResult result) {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .selectAsStartPoint(result);
    _startController.text = result.displayName;
    _animatedMapController.animateTo(dest: location, zoom: 15);
    FocusScope.of(context).unfocus();
    _tryFetchRoute();
  }

  void _onDestinationResultSelected(LocationResult result) {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .selectAsDestination(result);
    _destinationController.text = result.displayName;
    _animatedMapController.animateTo(dest: location, zoom: 15);
    FocusScope.of(context).unfocus();
    _tryFetchRoute();
  }

  void _tryFetchRoute() {
    final mapState = ref.read(mapViewModelProvider);
    final permissionState = ref.read(permissionViewModelProvider);

    // Start point belirlendi mi?
    final hasStart = mapState.useCurrentLocationAsStart
        ? permissionState.currentPosition != null
        : mapState.startPoint != null;

    // Destination belirlendi mi?
    final hasDestination = mapState.destination != null;

    if (hasStart && hasDestination) {
      ref.read(mapViewModelProvider.notifier).fetchRoute();
    }
  }

  void _useCurrentLocationAsStart() {
    ref.read(mapViewModelProvider.notifier).toggleCurrentLocationAsStart(true);
    _startController.text = AppStrings.currentLocation;
    ref.read(mapViewModelProvider.notifier).clearSearchResults();
    _tryFetchRoute();
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
    final permissionState = ref.watch(permissionViewModelProvider);
    final mapState = ref.watch(mapViewModelProvider);

    // İzinler kontrol ediliyor
    if (permissionState.isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // İzin verilmemiş
    if (!permissionState.hasPermission) {
      return const PermissionView();
    }

    final currentPosition = permissionState.currentPosition;
    final initialCenter = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : LatLng(37.7827875, 29.0966476);

    // Hata durumunu dinle ve SnackBar göster
    ref.listen<MapState>(mapViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: AppStrings.closeButton,
                  textColor: Colors.white,
                  onPressed: () {
                    ref.read(mapViewModelProvider.notifier).clearError();
                  },
                ),
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapTitle)),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _animatedMapController.mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: AppConstants.defaultZoom,
                    onPositionChanged: _onMapMove,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConstants.openStreetMapTileUrl,
                      userAgentPackageName: AppConstants.userAgentPackageName,
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
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          // Başlangıç marker'ı (mavi)
                          if (mapState.startPoint != null)
                            Marker(
                              point: mapState.startPoint!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.trip_origin,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          // Varış marker'ı (kırmızı)
                          if (mapState.destination != null)
                            Marker(
                              point: mapState.destination!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    // Rota çizgisi
                    if (mapState.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: mapState.routePoints,
                            color: Colors.blue,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                    const Scalebar(),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          AppStrings.openStreetMapAttribution,
                          onTap: () => launchUrl(
                            Uri.parse(AppConstants.openStreetMapCopyright),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Arama alanları
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Arama kutuları container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black12),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Başlangıç noktası
                        Row(
                          children: [
                            const Icon(
                              Icons.trip_origin,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _startController,
                                textInputAction: TextInputAction.search,
                                onChanged: _onStartSearchChanged,
                                onTap: () {
                                  if (_startController.text ==
                                      AppStrings.currentLocation) {
                                    _startController.clear();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: AppStrings.startPointHint,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_startController.text.isNotEmpty &&
                                          _startController.text !=
                                              AppStrings.currentLocation)
                                        IconButton(
                                          icon: Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _startController.clear();
                                            _useCurrentLocationAsStart();
                                          },
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.my_location,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        onPressed: _useCurrentLocationAsStart,
                                        tooltip: AppStrings.currentLocation,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        // Varış noktası
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _destinationController,
                                textInputAction: TextInputAction.search,
                                onChanged: _onDestinationSearchChanged,
                                decoration: InputDecoration(
                                  hintText: AppStrings.destinationHint,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  suffixIcon:
                                      _destinationController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _destinationController.clear();
                                            ref
                                                .read(
                                                  mapViewModelProvider.notifier,
                                                )
                                                .clearDestination();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Arama sonuçları
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
                          leading: Icon(
                            mapState.activeSearchField == SearchField.start
                                ? Icons.trip_origin
                                : Icons.location_on,
                            color:
                                mapState.activeSearchField == SearchField.start
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            result.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            if (mapState.activeSearchField ==
                                SearchField.start) {
                              _onStartResultSelected(result);
                            } else {
                              _onDestinationResultSelected(result);
                            }
                          },
                        );
                      },
                    ),
                  )
                else if (mapState.hasSearched &&
                    mapState.searchResults.isEmpty &&
                    !mapState.isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_off, color: Colors.grey),
                        SizedBox(width: 12),
                        Text(
                          AppStrings.noResultsFound,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
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
              heroTag: 'currentLocation',
              onPressed: _goToCurrentPosition,
              child: const Icon(Icons.my_location),
            ),
        ],
      ),
    );
  }
}
