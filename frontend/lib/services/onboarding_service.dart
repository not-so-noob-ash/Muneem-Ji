import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _hasSeenWelcomeKey = 'hasSeenWelcome';

  Future<bool> hasSeenWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenWelcomeKey) ?? false;
  }

  Future<void> setHasSeenWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, true);
  }
}
