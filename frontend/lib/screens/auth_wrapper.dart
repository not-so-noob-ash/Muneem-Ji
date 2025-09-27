import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState) {
      case AuthState.authenticated:
        return const HomeScreen();
      case AuthState.profileIncomplete:
        return const CompleteProfileScreen();
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.authenticating:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}

