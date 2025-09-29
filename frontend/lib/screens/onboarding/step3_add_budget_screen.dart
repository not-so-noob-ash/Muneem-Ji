import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  const AddBudgetScreen({super.key, required this.onFinish});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Groceries';
  String _recurrence = 'Monthly';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(onboardingProvider.notifier).addBudget(
        title: _titleController.text,
        category: _category,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        recurrence: _recurrence,
      );

      if (success && mounted) {
        widget.onFinish();
      } else {
        final error = ref.read(onboardingProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add budget')),
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
            Text('Set Your First Budget', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Budget Title (e.g., Monthly Groceries)'),
              validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              onChanged: (value) => setState(() => _category = value!),
              items: ['Groceries', 'Transport', 'Utilities', 'Entertainment', 'Rent']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Category'),
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
              items: ['Monthly', 'Weekly', 'Yearly']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Recurrence'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading ? const CircularProgressIndicator() : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

