import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const AddIncomeScreen({super.key, required this.onNext});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  String _recurrence = 'Monthly';
  int? _selectedBankAccountId;

  @override
  void initState() {
    super.initState();
    // Fetch accounts when the screen is first built
    Future.microtask(() => ref.read(onboardingProvider.notifier).fetchBankAccounts());
  }
  
  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a bank account')),
        );
        return;
      }

      final success = await ref.read(onboardingProvider.notifier).addIncome(
        bankAccountId: _selectedBankAccountId!,
        source: _sourceController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        recurrence: _recurrence,
      );

      if (success && mounted) {
        widget.onNext();
      } else {
        final error = ref.read(onboardingProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add income')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final bankAccounts = onboardingState.bankAccounts;
    final isLoading = onboardingState.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log Your Primary Income', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _selectedBankAccountId,
              hint: const Text('Receive In...'),
              onChanged: (value) => setState(() => _selectedBankAccountId = value),
              items: bankAccounts.map((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.bankName} (${account.accountType})'),
                );
              }).toList(),
              validator: (value) => value == null ? 'Please select an account' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Income Source (e.g., Salary)'),
              validator: (value) => value!.isEmpty ? 'Please enter a source' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter an amount';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recurrence,
              onChanged: (value) => setState(() => _recurrence = value!),
              items: ['Monthly', 'Weekly', 'One-Time']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Recurrence'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading ? const CircularProgressIndicator() : const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

