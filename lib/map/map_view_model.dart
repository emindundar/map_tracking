import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/map_repostory.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/permission/permission_view_model.dart';
import 'package:maptracking/util/constants.dart';
import 'package:geolocator/geolocator.dart';

enum SearchField { none, start, destination }

class MapState {
  final bool isAtCurrentPosition;
  final List<LatLng> markers;
  final String? errorMessage;
  final bool isSearching;
  final List<LatLng> routePoints;
  final Position? currentPositionStream;
  final bool isNavigating;

  // Start point
  final LatLng? startPoint;
  final String? startPointName;
  final bool useCurrentLocationAsStart;

  // Destination
  final LatLng? destination;
  final String? destinationName;

  // Search
  final SearchField activeSearchField;
  final List<LocationResult> searchResults;
  final bool hasSearched;

  const MapState({
    this.isAtCurrentPosition = true,
    this.markers = const [],
    this.errorMessage,
    this.isSearching = false,
    this.routePoints = const [],
    this.startPoint,
    this.startPointName,
    this.useCurrentLocationAsStart = true,
    this.destination,
    this.destinationName,
    this.activeSearchField = SearchField.none,
    this.searchResults = const [],
    this.hasSearched = false,
    this.currentPositionStream,
    this.isNavigating = false,
  });

  MapState copyWith({
    bool? isAtCurrentPosition,
    List<LatLng>? markers,
    String? errorMessage,
    bool? isSearching,
    List<LatLng>? routePoints,
    LatLng? startPoint,
    String? startPointName,
    bool? useCurrentLocationAsStart,
    LatLng? destination,
    String? destinationName,
    SearchField? activeSearchField,
    List<LocationResult>? searchResults,
    bool? hasSearched,
    bool clearError = false,
    bool clearStartPoint = false,
    bool clearDestination = false,
    Position? currentPositionStream,
    bool? isNavigating,
  }) {
    return MapState(
      isAtCurrentPosition: isAtCurrentPosition ?? this.isAtCurrentPosition,
      markers: markers ?? this.markers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSearching: isSearching ?? this.isSearching,
      routePoints: routePoints ?? this.routePoints,
      startPoint: clearStartPoint ? null : (startPoint ?? this.startPoint),
      startPointName: clearStartPoint
          ? null
          : (startPointName ?? this.startPointName),
      useCurrentLocationAsStart:
          useCurrentLocationAsStart ?? this.useCurrentLocationAsStart,
      destination: clearDestination ? null : (destination ?? this.destination),
      destinationName: clearDestination
          ? null
          : (destinationName ?? this.destinationName),
      activeSearchField: activeSearchField ?? this.activeSearchField,
      searchResults: searchResults ?? this.searchResults,
      hasSearched: hasSearched ?? this.hasSearched,
      currentPositionStream:
          currentPositionStream ?? this.currentPositionStream,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}

class MapViewModel extends StateNotifier<MapState> {
  final MapRepository _repository;
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;

  MapViewModel(this._ref)
    : _repository = _ref.read(mapRepositoryProvider),
      super(const MapState());

  @override
  void dispose() {
    _stopPositionStream();
    super.dispose();
  }

  Future<void> searchLocation(String query, SearchField field) async {
    if (query.length <= 2) {
      state = state.copyWith(
        searchResults: [],
        clearError: true,
        hasSearched: false,
        activeSearchField: field,
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      clearError: true,
      activeSearchField: field,
    );

    final result = await _repository.searchLocation(query);

    if (result.hasError) {
      state = state.copyWith(
        searchResults: [],
        errorMessage: result.error,
        isSearching: false,
        hasSearched: true,
      );
    } else {
      state = state.copyWith(
        searchResults: result.data,
        isSearching: false,
        clearError: true,
        hasSearched: true,
      );
    }
  }

  void clearSearchResults() {
    state = state.copyWith(
      searchResults: [],
      clearError: true,
      hasSearched: false,
      activeSearchField: SearchField.none,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> fetchRoute() async {
    final permissionState = _ref.read(permissionViewModelProvider);
    final currentPosition = permissionState.currentPosition;
    final destination = state.destination;

    LatLng? start;
    if (state.useCurrentLocationAsStart && currentPosition != null) {
      start = LatLng(currentPosition.latitude, currentPosition.longitude);
    } else {
      start = state.startPoint;
    }

    if (start == null || destination == null) {
      if (kDebugMode) {
        print('fetchRoute: Başlangıç veya hedef bulunamadı');
      }
      return;
    }

    final result = await _repository.getRoute(start, destination);

    if (result.hasError) {
      state = state.copyWith(errorMessage: result.error, routePoints: []);
    } else {
      state = state.copyWith(routePoints: result.coordinates, clearError: true);
    }
  }

  void clearRoute() {
    state = state.copyWith(routePoints: []);
  }

  LatLng selectAsStartPoint(LocationResult result) {
    if (kDebugMode) {
      print('Başlangıç seçildi: ${result.displayName}');
    }

    final updatedMarkers = [
      result.latLng,
      if (state.destination != null) state.destination!,
    ];

    state = state.copyWith(
      startPoint: result.latLng,
      startPointName: result.displayName,
      useCurrentLocationAsStart: false,
      markers: updatedMarkers,
      searchResults: [],
      hasSearched: false,
      activeSearchField: SearchField.none,
    );

    return result.latLng;
  }

  LatLng selectAsDestination(LocationResult result) {
    if (kDebugMode) {
      print('Varış seçildi: ${result.displayName}');
    }

    final updatedMarkers = [
      if (state.startPoint != null) state.startPoint!,
      result.latLng,
    ];

    state = state.copyWith(
      destination: result.latLng,
      destinationName: result.displayName,
      markers: updatedMarkers,
      searchResults: [],
      hasSearched: false,
      activeSearchField: SearchField.none,
    );

    return result.latLng;
  }

  void toggleCurrentLocationAsStart(bool useCurrentLocation) {
    state = state.copyWith(
      useCurrentLocationAsStart: useCurrentLocation,
      clearStartPoint: useCurrentLocation,
    );
  }

  void clearStartPoint() {
    //kullanılmadı
    state = state.copyWith(
      clearStartPoint: true,
      useCurrentLocationAsStart: true,
    );
  }

  void clearDestination() {
    state = state.copyWith(
      clearDestination: true,
      routePoints: [],
      markers: [],
    );
  }

  void setIsAtCurrentPosition(bool value) {
    if (state.isAtCurrentPosition != value) {
      state = state.copyWith(isAtCurrentPosition: value);
    }
  }

  void onMapMove(double centerLat, double centerLon) {
    final permissionState = _ref.read(permissionViewModelProvider);
    if (permissionState.currentPosition == null) return;

    final currentLat = permissionState.currentPosition!.latitude;
    final currentLon = permissionState.currentPosition!.longitude;

    const tolerance = AppConstants.positionTolerance;
    final isNear =
        (centerLat - currentLat).abs() < tolerance &&
        (centerLon - currentLon).abs() < tolerance;

    setIsAtCurrentPosition(isNear);
  }

  LatLng? goToCurrentPosition() {
    final permissionState = _ref.read(permissionViewModelProvider);
    if (permissionState.currentPosition == null) return null;

    state = state.copyWith(isAtCurrentPosition: true);

    return LatLng(
      permissionState.currentPosition!.latitude,
      permissionState.currentPosition!.longitude,
    );
  }

  /// Navigasyonu başlatır ve konum stream'ini aktif eder
  void startNavigation() {
    if (state.isNavigating) return;

    state = state.copyWith(isNavigating: true);
    _startPositionStream();

    if (kDebugMode) {
      print('Navigasyon başlatıldı, konum stream aktif');
    }
  }

  /// Navigasyonu durdurur ve konum stream'ini kapatır (pil optimizasyonu)
  void stopNavigation() {
    if (!state.isNavigating) return;

    _stopPositionStream();
    state = state.copyWith(isNavigating: false, currentPositionStream: null);

    if (kDebugMode) {
      print('Navigasyon durduruldu, konum stream kapatıldı');
    }
  }

  /// Konum stream'ini başlatır
  void _startPositionStream() {
    _positionStreamSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      //süre bazlı güncelleme eklenebilir
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            state = state.copyWith(currentPositionStream: position);

            if (kDebugMode) {
              print('Yeni konum: ${position.latitude}, ${position.longitude}');
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print('Konum stream hatası: $error');
            }
            state = state.copyWith(errorMessage: 'Konum alınamadı: $error');
          },
        );
  }

  /// Konum stream'ini durdurur
  void _stopPositionStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}

// MapViewModel Provider
final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((
  ref,
) {
  return MapViewModel(ref);
});
