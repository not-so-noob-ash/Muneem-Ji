import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_account_model.dart';
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  int? _selectedBankAccountId;
  String _recurrence = 'Monthly';
  bool _isLoading = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank account.')));
        return;
      }
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        final token = ref.read(authProvider).token!;
        await apiService.addIncome(
          token: token,
          bankAccountId: _selectedBankAccountId!,
          source: _sourceController.text,
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
    final bankAccounts = ref.watch(dashboardProvider).bankAccounts;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income Source')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Income Source'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedBankAccountId,
                decoration: const InputDecoration(labelText: 'Receive In Account'),
                items: bankAccounts.map((account) => DropdownMenuItem(value: account.id, child: Text(account.bankName))).toList(),
                onChanged: (val) => setState(() => _selectedBankAccountId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrence,
                items: ['Monthly', 'Weekly', 'One-Time'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setState(() => _recurrence = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text('Add Income')),
            ],
          ),
        ),
      ),
    );
  }
}