import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart'; // Import the new splash screen

void main() {
  runApp(
    const ProviderScope(
      child: MuneemJiApp(),
    ),
  );
}

class MuneemJiApp extends StatelessWidget {
  const MuneemJiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muneem Ji',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
          primary: Colors.tealAccent[400],
          secondary: Colors.purpleAccent[100],
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        // CORRECTED: Changed CardTheme to CardThemeData
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.grey[850],
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent[400],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[800],
        ),
        // Add other theme properties as needed
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // The new entry point
    );
  }
}

