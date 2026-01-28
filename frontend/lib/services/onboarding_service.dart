import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingService {
  static const _keyHasSeenWelcome = 'hasSeenWelcome';

  Future<bool> hasSeenWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenWelcome) ?? false;
  }

  Future<void> setWelcomeScreenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenWelcome, true);
  }
}

final onboardingServiceProvider = Provider((ref) => OnboardingService());

