import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maptracking/auth/storage_service.dart';
import 'package:maptracking/util/constants.dart';

class AuthService {
  late final StorageService _storageService;
Future<bool> register(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.authBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final token = data['accessToken'];
      
      if (token != null) {
        await _storageService.saveToken(token); 
        return true; 
      }
    }
    return false;
  } catch (e) {
    return false;
  }
}
}