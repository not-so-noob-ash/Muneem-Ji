import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';
import 'auth_wrapper.dart';
import 'welcome_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Give a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    final onboardingService = ref.read(onboardingServiceProvider);
    final hasSeenWelcome = await onboardingService.hasSeenWelcomeScreen();

    if (mounted) {
      if (hasSeenWelcome) {
        // User has seen the welcome screen, go to the auth wrapper
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      } else {
        // First time user, show the welcome screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Added the logo here
            Image.asset('assets/logo.png', height: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

