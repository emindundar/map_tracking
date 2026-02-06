import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/map/widgets/map_search_widgets.dart';
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
    super.dispose();
  }

  void _onStartSearchChanged(String query) {
    ref
        .read(mapViewModelProvider.notifier)
        .onSearchQueryChanged(query, SearchField.start);
  }

  void _onDestinationSearchChanged(String query) {
    ref
        .read(mapViewModelProvider.notifier)
        .onSearchQueryChanged(query, SearchField.destination);
  }

  void _onStartResultSelected(LocationResult result) {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .selectAsStartPoint(result);
    _startController.text = result.displayName;
    _animatedMapController.animateTo(dest: location, zoom: 15);
    FocusScope.of(context).unfocus();
  }

  void _onDestinationResultSelected(LocationResult result) {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .selectAsDestination(result);
    _destinationController.text = result.displayName;
    _animatedMapController.animateTo(dest: location, zoom: 15);
    FocusScope.of(context).unfocus();
  }

  void _useCurrentLocationAsStart() {
    ref.read(mapViewModelProvider.notifier).toggleCurrentLocationAsStart(true);
    _startController.text = AppStrings.currentLocation;
    ref.read(mapViewModelProvider.notifier).clearSearchResults();
  }

  void _startNavigation() {
    final success = ref.read(mapViewModelProvider.notifier).startNavigation();

    if (success) {
      final permissionState = ref.read(permissionViewModelProvider);
      final currentPosition = permissionState.currentPosition;

      if (currentPosition != null) {
        _animatedMapController.animateTo(
          dest: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: AppConstants.navigationZoom,
          rotation: 0, // Kuzeye kilitle
        );
      }
    }
  }

  void _stopNavigation() {
    ref.read(mapViewModelProvider.notifier).stopNavigation();

    // Zoom'u normale döndür
    _animatedMapController.animatedZoomTo(AppConstants.defaultZoom);
  }

  void _goToCurrentPosition() {
    final location = ref
        .read(mapViewModelProvider.notifier)
        .goToCurrentPosition();
    if (location != null) {
      _animatedMapController.animateTo(
        dest: location,
        zoom: AppConstants.defaultZoom,
      );
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

      // Navigasyon aktifken konum değiştiğinde haritayı takip et
      if (next.isNavigating &&
          next.currentPositionStream != null &&
          previous?.currentPositionStream != next.currentPositionStream) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animatedMapController.animateTo(
            dest: LatLng(
              next.currentPositionStream!.latitude,
              next.currentPositionStream!.longitude,
            ),
            zoom: AppConstants.navigationZoom,
            rotation: 0, // Kuzeye kilitli
          );
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
                          // Kullanıcının mevcut konumu - navigasyon aktifse stream'den al
                          Marker(
                            point:
                                mapState.isNavigating &&
                                    mapState.currentPositionStream != null
                                ? LatLng(
                                    mapState.currentPositionStream!.latitude,
                                    mapState.currentPositionStream!.longitude,
                                  )
                                : LatLng(
                                    currentPosition.latitude,
                                    currentPosition.longitude,
                                  ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              mapState.isNavigating
                                  ? Icons.navigation
                                  : Icons.my_location,
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
          MapSearchWidgets(
            startController: _startController,
            destinationController: _destinationController,
            mapState: mapState,
            onStartSearchChanged: _onStartSearchChanged,
            onDestinationSearchChanged: _onDestinationSearchChanged,
            onStartResultSelected: _onStartResultSelected,
            onDestinationResultSelected: _onDestinationResultSelected,
            onUseCurrentLocationAsStart: _useCurrentLocationAsStart,
            onClearDestination: () {
              ref.read(mapViewModelProvider.notifier).clearDestination();
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Navigasyon başlat/durdur butonu (rota varsa göster)
          if (mapState.routePoints.isNotEmpty)
            FloatingActionButton(
              heroTag: 'navigation',
              backgroundColor: mapState.isNavigating
                  ? Colors.red
                  : Colors.green,
              onPressed: mapState.isNavigating
                  ? _stopNavigation
                  : _startNavigation,
              child: Icon(
                mapState.isNavigating ? Icons.stop : Icons.navigation,
                color: Colors.white,
              ),
            ),
          if (mapState.routePoints.isNotEmpty) const SizedBox(height: 8),
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
          if (!mapState.isAtCurrentPosition && !mapState.isNavigating)
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
