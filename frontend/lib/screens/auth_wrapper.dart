import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart'; // Import the navigation wrapper

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      if (authState.isProfileComplete) {
        // Corrected: Point to MainNavigationScreen
        return const MainNavigationScreen();
      } else {
        return const CompleteProfileScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}