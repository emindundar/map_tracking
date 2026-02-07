import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maptracking/auth/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? token;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? token,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      token: token ?? this.token,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthViewModel(this._authService) : super(const AuthState());

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.register(email, password);

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, token: result.token);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.errorMessage,
    );

    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.login(email, password);

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, token: result.token);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: result.errorMessage,
    );

    return false;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
      final authService = ref.read(authServiceProvider);
      return AuthViewModel(authService);
    });
