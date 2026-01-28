import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class MapRepository {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'com.emindundar.maptracking';

  Future<List<Map<String, dynamic>>> searchLocation(
    String query, {
    int limit = 3,
  }) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('$_baseUrl/search?q=$query&format=json&limit=$limit');

    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (kDebugMode) {
          print('Bulunan sonuç sayısı: ${data.length}');
        }
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: API hatası $e");
      }
    }
    return [];
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});
