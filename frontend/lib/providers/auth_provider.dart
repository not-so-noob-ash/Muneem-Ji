import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/token_storage_service.dart';

// 1. Corrected AuthState class
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? token;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.token,
    this.user,
  });

  bool get isAuthenticated => token != null;
  bool get isProfileComplete => user?.isProfileComplete ?? false;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? token,
    User? user,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Always update error message
      token: clearToken ? null : token ?? this.token,
      user: clearUser ? null : user ?? this.user,
    );
  }
}


class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final TokenStorageService _tokenStorage;

  AuthNotifier(this._apiService, this._tokenStorage) : super(AuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _tokenStorage.getToken();
    if (token != null) {
      try {
        final user = await _apiService.getMe(token);
        state = state.copyWith(token: token, user: user);
      } catch (e) {
        // Token is invalid, log out
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.login(email, password);
      final token = response['access_token'];
      await _tokenStorage.saveToken(token);
      final user = await _apiService.getMe(token);
      state = state.copyWith(isLoading: false, token: token, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
  
  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
     try {
      await _apiService.register(email, password);
      // After successful registration, log the user in
      return await login(email, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String upiId,
    required String preferredCurrency,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedUser = await _apiService.updateProfile(
        token: state.token!,
        fullName: fullName,
        upiId: upiId,
        preferredCurrency: preferredCurrency,
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    state = state.copyWith(clearToken: true, clearUser: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService(), TokenStorageService());
});

