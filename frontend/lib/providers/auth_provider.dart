import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/token_storage_service.dart';

// Enum to represent the authentication state
enum AuthState {
  checking,
  loggedIn,
  loggedOut,
}

// The StateNotifier that will hold our authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._apiService, this._tokenStorage) : super(AuthState.checking) {
    _checkToken();
  }

  final ApiService _apiService;
  final TokenStorageService _tokenStorage;

  // Check if a token exists on startup
  Future<void> _checkToken() async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      state = AuthState.loggedIn;
    } else {
      state = AuthState.loggedOut;
    }
  }

  Future<void> register(String email, String password) async {
    try {
      await _apiService.register(email, password);
      // After successful registration, log the user in
      await login(email, password);
    } catch (e) {
      // Re-throw the exception to be caught in the UI
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final token = await _apiService.login(email, password);
      await _tokenStorage.saveToken(token);
      state = AuthState.loggedIn;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    state = AuthState.loggedOut;
  }
}

// The Riverpod provider for our AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // We can get other providers using ref.watch
  final apiService = ref.watch(apiServiceProvider);
  final tokenStorage = TokenStorageService();
  return AuthNotifier(apiService, tokenStorage);
});
