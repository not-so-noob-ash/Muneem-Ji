import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Use if/else checks on the properties of the AuthState class
    if (authState.isAuthenticated) {
      if (authState.isProfileComplete) {
        // User is logged in and profile is complete -> Show Home
        return const HomeScreen();
      } else {
        // User is logged in but profile is incomplete -> Show Profile Form
        return const CompleteProfileScreen();
      }
    } else {
      // User is not logged in -> Show Login
      return const LoginScreen();
    }
  }
}

