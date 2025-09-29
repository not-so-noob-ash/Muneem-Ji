import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

class AddBankScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const AddBankScreen({super.key, required this.onNext});

  @override
  ConsumerState<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends ConsumerState<AddBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _accountType = 'Savings';

  @override
  void dispose() {
    _bankNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Correctly read the user from the authProvider state
      final user = ref.read(authProvider).user;
      if (user == null || user.preferredCurrency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find user profile. Please restart.'))
        );
        return;
      }
      
      final success = await ref.read(onboardingProvider.notifier).addBankAccount(
        bankName: _bankNameController.text,
        accountType: _accountType,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
        currency: user.preferredCurrency!,
      );

      if (success && mounted) {
        widget.onNext();
      } else if (mounted) {
        final error = ref.read(onboardingProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add bank account')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Your Primary Bank Account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name'),
              validator: (value) => value!.isEmpty ? 'Please enter a bank name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _accountType,
              onChanged: (value) => setState(() => _accountType = value!),
              items: ['Savings', 'Checking', 'Credit Card']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Account Type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Current Balance'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a balance';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

