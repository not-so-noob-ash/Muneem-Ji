import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // The ProviderScope is what makes Riverpod work.
  // It stores the state of all our providers.
  runApp(const ProviderScope(child: MuneemJiApp()));
}

class MuneemJiApp extends StatelessWidget {
  const MuneemJiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muneem Ji',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), // Our initial screen
    );
  }
}

// A simple placeholder screen to confirm our setup is working.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muneem Ji'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Welcome to Muneem Ji!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
