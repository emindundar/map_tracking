import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/core/widgets/widgets.dart';
import 'package:maptracking/map/map_view_model.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/map/widgets/map_control_stack.dart';
import 'package:maptracking/map/widgets/map_search_bar.dart';
import 'package:maptracking/map/widgets/map_search_sheet.dart';
import 'package:maptracking/map/widgets/route_summary_card.dart';
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
      return const Scaffold(body: Center(child: CustomProgressBar()));
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

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetVisible =
        mapState.isSearching ||
        mapState.searchResults.isNotEmpty ||
        mapState.hasSearched;
    final estimatedSheetHeight = sheetVisible
        ? _estimateSheetHeight(context, mapState)
        : 0.0;
    final overlayBottom =
        sheetVisible ? estimatedSheetHeight + 16.0 : 24.0;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
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
                        size: 38,
                      ),
                    ),
                    if (mapState.startPoint != null)
                      Marker(
                        point: mapState.startPoint!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.trip_origin,
                          color: Colors.blue,
                          size: 34,
                        ),
                      ),
                    if (mapState.destination != null)
                      Marker(
                        point: mapState.destination!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                  ],
                ),
              if (mapState.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.routePoints,
                      color: const Color(0xFF1E2A3A),
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
          if (sheetVisible)
            MapSearchSheet(
              mapState: mapState,
              onStartResultSelected: _onStartResultSelected,
              onDestinationResultSelected: _onDestinationResultSelected,
            ),
          if (mapState.routePoints.isNotEmpty)
            Positioned(
              left: 16,
              right: 88,
              bottom: overlayBottom,
              child: RouteSummaryCard(
                distanceMeters: mapState.routeDistanceMeters,
                durationSeconds: mapState.routeDurationSeconds,
              ),
            ),
          Positioned(
            right: 16,
            bottom: overlayBottom + (mapState.routePoints.isNotEmpty ? 76 : 0),
            child: MapControlStack(
              isNavigating: mapState.isNavigating,
              hasRoute: mapState.routePoints.isNotEmpty,
              onStartNavigation: _startNavigation,
              onStopNavigation: _stopNavigation,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onGoToCurrentLocation: _goToCurrentPosition,
              showCurrentLocation:
                  !mapState.isAtCurrentPosition && !mapState.isNavigating,
            ),
          ),
          MapSearchBar(
            startController: _startController,
            destinationController: _destinationController,
            onStartSearchChanged: _onStartSearchChanged,
            onDestinationSearchChanged: _onDestinationSearchChanged,
            onUseCurrentLocationAsStart: _useCurrentLocationAsStart,
            onClearDestination: () {
              ref.read(mapViewModelProvider.notifier).clearDestination();
            },
          ),
        ],
      ),
    );
  }

  double _estimateSheetHeight(BuildContext context, MapState state) {
    final maxHeight = MediaQuery.of(context).size.height * 0.45;
    const headerHeight = 88.0;
    const emptyStateHeight = 72.0;
    const listTileHeight = 72.0;

    final items = state.searchResults.isNotEmpty
        ? state.searchResults.length
        : 1;
    final listHeight = state.searchResults.isNotEmpty
        ? items * listTileHeight
        : emptyStateHeight;

    return math.min(maxHeight, headerHeight + listHeight);
  }
}
