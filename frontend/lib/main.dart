import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth_wrapper.dart';

void main() {
  runApp(const ProviderScope(child: MuneemJiApp()));
}

class MuneemJiApp extends StatelessWidget {
  const MuneemJiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muneem Ji',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
        ),
      ),
      // The AuthWrapper will decide which screen to show
      home: const AuthWrapper(),
    );
  }
}

