import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:maptracking/map/location_result_model.dart';
import 'package:maptracking/util/constants.dart';

class SearchResult {
  final List<LocationResult> data;
  final String? error;

  SearchResult({required this.data, this.error});

  bool get hasError => error != null;
}

class RouteResult {
  final List<LatLng> coordinates;
  final String? error;
  final double? distance;
  final double? duration;

  RouteResult({
    required this.coordinates,
    this.error,
    this.distance,
    this.duration,
  });

  bool get hasError => error != null;
}

class MapRepository {
  Future<SearchResult> searchLocation(String query, {int? limit}) async {
    if (query.isEmpty) return SearchResult(data: []);

    final searchLimit = limit ?? AppConstants.searchLimit;
    final url = Uri.parse(
      '${AppConstants.nominatimBaseUrl}/search?q=$query&format=json&limit=$searchLimit',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': AppConstants.userAgentPackageName},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (kDebugMode) {
          print('Bulunan sonuç sayısı: ${data.length}');
        }
        final results = data
            .map((json) => LocationResult.fromJson(json))
            .toList();
        return SearchResult(data: results);
      } else {
        return SearchResult(
          data: [],
          error: '${AppStrings.serverError} ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: API hatası $e");
      }
      return SearchResult(data: [], error: AppStrings.searchError);
    }
  }
//kullanmayı unutma
  Future<RouteResult> getRoute(LatLng start, LatLng destination) async {
    final url = Uri.parse(
      '${AppConstants.osrmBaseUrl}/route/v1/driving/'
      '${start.longitude},${start.latitude};' 
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final routePoints = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          final distance = route['distance']?.toDouble(); 
          final duration = route['duration']?.toDouble(); 

          if (kDebugMode) {
            print(
              'Rota alındı: ${routePoints.length} nokta, '
              '${(distance ?? 0) / 1000} km, '
              '${((duration ?? 0) / 60).toStringAsFixed(1)} dakika',
            );
          }

          return RouteResult(
            coordinates: routePoints,
            distance: distance,
            duration: duration,
          );
        } else {
          return RouteResult(
            coordinates: [],
            error: data['message'] ?? AppStrings.routeError,
          );
        }
      } else {
        return RouteResult(
          coordinates: [],
          error: '${AppStrings.serverError} ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: OSRM hatası $e");
      }
      return RouteResult(coordinates: [], error: AppStrings.routeError);
    }
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});
