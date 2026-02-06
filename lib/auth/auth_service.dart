import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maptracking/auth/user_models.dart';
import 'package:maptracking/core/init/storage/storage_service.dart';
import 'package:maptracking/util/constants.dart';

enum AuthFailureType {
  network,
  invalidCredentials,
  server,
  tokenMissing,
  unknown,
}

class AuthFailure {
  final AuthFailureType type;
  final String message;

  const AuthFailure(this.type, this.message);
}

class AuthResult {
  final bool isSuccess;
  final String? token;
  final UserModel? user;
  final AuthFailure? failure;

  const AuthResult._({
    required this.isSuccess,
    this.token,
    this.user,
    this.failure,
  });

  factory AuthResult.success(String token, {UserModel? user}) =>
      AuthResult._(isSuccess: true, token: token, user: user);

  const AuthResult.failure(AuthFailure failure)
    : this._(isSuccess: false, failure: failure);

  String? get errorMessage => failure?.message;
}

class AuthService {
  final StorageService _storageService;

  AuthService(this._storageService);

  Future<AuthResult> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.authBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponseModel.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _storageService.saveToken(authResponse.token!);
          return AuthResult.success(
            authResponse.token!,
            user: authResponse.user,
          );
        }

        // success: false veya token yok
        return AuthResult.failure(
          AuthFailure(
            AuthFailureType.tokenMissing,
            authResponse.message.isNotEmpty
                ? authResponse.message
                : AppStrings.authTokenMissing,
          ),
        );
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        final message = _extractMessage(response.body);
        return AuthResult.failure(
          AuthFailure(
            AuthFailureType.invalidCredentials,
            message ?? AppStrings.authInvalidCredentials,
          ),
        );
      }

      final message = _extractMessage(response.body);
      return AuthResult.failure(
        AuthFailure(
          AuthFailureType.server,
          message ?? AppStrings.authServerError,
        ),
      );
    } on http.ClientException {
      return const AuthResult.failure(
        AuthFailure(AuthFailureType.network, AppStrings.authNetworkError),
      );
    } catch (_) {
      return const AuthResult.failure(
        AuthFailure(AuthFailureType.unknown, AppStrings.authUnexpectedError),
      );
    }
  }

  Future<String?> getSavedToken() async {
    return _storageService.getToken();
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return AuthService(storageService);
});

final authTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getSavedToken();
});
