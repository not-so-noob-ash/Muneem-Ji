import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart'; // Navigate to HomeScreen

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR'); // Default

  @override
  void dispose() {
    _fullNameController.dispose();
    _upiIdController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).updateProfile(
            fullName: _fullNameController.text,
            upiId: _upiIdController.text,
            preferredCurrency: _currencyController.text,
          );
      if (success && mounted) {
        // Navigate to the HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Just a few more details to get you started!",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(labelText: 'UPI ID'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your UPI ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(labelText: 'Preferred Currency (e.g., INR)'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your currency' : null,
              ),
              const SizedBox(height: 32),
              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authState.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _submitProfile,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save and Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

