import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Food';
  String _recurrence = 'Monthly';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        final token = ref.read(authProvider).token!;
        await apiService.addBudget(
          token: token,
          title: _titleController.text,
          category: _category,
          amount: double.parse(_amountController.text),
          recurrence: _recurrence,
        );
        ref.read(dashboardProvider.notifier).fetchDashboardData();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Budget Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Food', 'Transport', 'Utilities', 'Entertainment', 'Rent', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monthly Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrence,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: ['Monthly', 'Weekly', 'Yearly'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setState(() => _recurrence = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('Add Budget')),
            ],
          ),
        ),
      ),
    );
  }
}