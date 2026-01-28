import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/map_repository.dart';
import 'package:maptracking/permisson/permission_service.dart';

// Permission Status Provider
final permissionStatusProvider = FutureProvider<LocationPermission>((
  ref,
) async {
  return await PermissionService.requestLocationPermission();
});

// Current Position Provider
final currentPositionProvider = FutureProvider<Position>((ref) async {
  return await PermissionService.getUserCurrentPosition();
});

// MapState - Tüm UI durumunu tutar
class MapState {
  final bool hasPermission;
  final bool isChecking;
  final Position? currentPosition;
  final bool isAtCurrentPosition;
  final List<LatLng> markers;
  final List<Map<String, dynamic>> searchResults;
  final String? selectedLocationName;

  const MapState({
    this.hasPermission = false,
    this.isChecking = true,
    this.currentPosition,
    this.isAtCurrentPosition = true,
    this.markers = const [],
    this.searchResults = const [],
    this.selectedLocationName,
  });

  MapState copyWith({
    bool? hasPermission,
    bool? isChecking,
    Position? currentPosition,
    bool? isAtCurrentPosition,
    List<LatLng>? markers,
    List<Map<String, dynamic>>? searchResults,
    String? selectedLocationName,
  }) {
    return MapState(
      hasPermission: hasPermission ?? this.hasPermission,
      isChecking: isChecking ?? this.isChecking,
      currentPosition: currentPosition ?? this.currentPosition,
      isAtCurrentPosition: isAtCurrentPosition ?? this.isAtCurrentPosition,
      markers: markers ?? this.markers,
      searchResults: searchResults ?? this.searchResults,
      selectedLocationName: selectedLocationName ?? this.selectedLocationName,
    );
  }
}

// MapViewModel - İş mantığını yönetir
class MapViewModel extends StateNotifier<MapState> {
  final MapRepository _repository;

  MapViewModel(Ref ref)
    : _repository = ref.read(mapRepositoryProvider),
      super(const MapState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkPermission();
  }

  Future<void> checkPermission() async {
    final status = await PermissionService.requestLocationPermission();

    final hasPermission =
        status == LocationPermission.whileInUse ||
        status == LocationPermission.always;

    if (hasPermission) {
      await getCurrentPosition();
    }

    state = state.copyWith(hasPermission: hasPermission, isChecking: false);
  }

  Future<void> getCurrentPosition() async {
    final position = await PermissionService.getUserCurrentPosition();
    state = state.copyWith(currentPosition: position);
  }

  void onPermissionGranted() {
    getCurrentPosition();
    state = state.copyWith(hasPermission: true, isChecking: false);
  }

  Future<void> searchLocation(String query) async {
    if (query.length <= 2) {
      state = state.copyWith(searchResults: []);
      return;
    }

    final results = await _repository.searchLocation(query);
    state = state.copyWith(searchResults: results);
  }

  void clearSearchResults() {
    state = state.copyWith(searchResults: []);
  }

  LatLng? selectSearchResult(Map<String, dynamic> result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final location = LatLng(lat, lon);

    if (kDebugMode) {
      print('Seçilen: ${result['display_name']}');
    }

    // Önceki marker'ları temizle, sadece yeni marker'ı ekle
    final updatedMarkers = [location];

    state = state.copyWith(
      markers: updatedMarkers,
      searchResults: [],
      selectedLocationName: result['display_name'],
    );

    return location;
  }

  void setIsAtCurrentPosition(bool value) {
    if (state.isAtCurrentPosition != value) {
      state = state.copyWith(isAtCurrentPosition: value);
    }
  }

  void onMapMove(double centerLat, double centerLon) {
    if (state.currentPosition == null) return;

    final currentLat = state.currentPosition!.latitude;
    final currentLon = state.currentPosition!.longitude;

    const tolerance = 0.005;
    final isNear =
        (centerLat - currentLat).abs() < tolerance &&
        (centerLon - currentLon).abs() < tolerance;

    setIsAtCurrentPosition(isNear);
  }

  LatLng? goToCurrentPosition() {
    if (state.currentPosition == null) return null;

    state = state.copyWith(isAtCurrentPosition: true);

    return LatLng(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
    );
  }
}

// MapViewModel Provider
final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((
  ref,
) {
  return MapViewModel(ref);
});
