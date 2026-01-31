import 'package:latlong2/latlong.dart';

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;
  final String? type;
  final String? placeId;

  const LocationResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.type,
    this.placeId,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      type: json['type'],
      placeId: json['place_id']?.toString(),//geliyor mu
    );
  }

  LatLng get latLng => LatLng(lat, lon);

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'type': type,
      'place_id': placeId,
    };
  }

  @override
  String toString() =>
      'LocationResult(displayName: $displayName, lat: $lat, lon: $lon)';
}
