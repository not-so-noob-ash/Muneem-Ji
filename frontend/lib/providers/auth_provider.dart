import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/token_storage_service.dart';
import '../models/user_model.dart';

// Enum to represent the different states of authentication
enum AuthState {
  unauthenticated,
  authenticating,
  profileIncomplete,
  authenticated,
}

// The state object that our provider will manage
class AuthStateNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final TokenStorageService _tokenStorage;
  User? currentUser;
  String? _token;

  AuthStateNotifier(this._apiService, this._tokenStorage) : super(AuthState.unauthenticated) {
    _init();
  }

  // Check for a saved token on app startup
  Future<void> _init() async {
    _token = await _tokenStorage.getToken();
    if (_token != null) {
      await _verifyTokenAndFetchUser();
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> _verifyTokenAndFetchUser() async {
    state = AuthState.authenticating;
    final response = await _apiService.getMe(_token!);
    if (response['success']) {
      currentUser = User.fromJson(response['data']);
      if (currentUser!.isProfileComplete) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.profileIncomplete;
      }
    } else {
      await logout(); // Token is invalid or expired
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      if (response['success']) {
        _token = response['token'];
        await _tokenStorage.saveToken(_token!);
        await _verifyTokenAndFetchUser();
        return null; // Success
      } else {
        return response['message'];
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final response = await _apiService.register(email, password);
      if (response['success']) {
        // Automatically log in the user after successful registration
        return await login(email, password);
      } else {
        return response['message'];
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfile(String fullName, String upiId, String currency) async {
    try {
      final response = await _apiService.updateProfile(
        token: _token!,
        fullName: fullName,
        upiId: upiId,
        preferredCurrency: currency,
      );
      if (response['success']) {
        await _verifyTokenAndFetchUser(); // Re-fetch user to confirm profile is complete
        return null;
      } else {
        return response['message'];
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    await _tokenStorage.deleteToken();
    state = AuthState.unauthenticated;
  }
}

// --- Providers ---

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final tokenStorageProvider = Provider<TokenStorageService>((ref) => TokenStorageService());

final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthStateNotifier(apiService, tokenStorage);
});

