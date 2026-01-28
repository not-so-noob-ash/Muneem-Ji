import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure url_launcher is in pubspec
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/bank_account_model.dart';
import 'qr_scanner_screen.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController(); 
  
  // State Variables
  String _category = 'Food';
  String _paymentMethod = 'cash'; 
  int? _selectedBankAccountId;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 1. QR SCANNING & DIRECT LAUNCH LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _scanQRCode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedCode != null) {
      if (scannedCode.startsWith('upi://')) {
        // Direct Launch Logic: We don't parse, we just pass the URI to the OS
        final uri = Uri.parse(scannedCode);
        try {
          if (await canLaunchUrl(uri)) {
             // Force payment method to UPI since we are scanning a UPI code
             setState(() {
               _paymentMethod = 'upi';
               // Auto-select the first bank account if none selected
                final bankAccounts = ref.read(dashboardProvider).bankAccounts;
                if (_selectedBankAccountId == null && bankAccounts.isNotEmpty) {
                  _selectedBankAccountId = bankAccounts.first.id;
                }
             });
             
             // Launch the external UPI app
             await launchUrl(uri, mode: LaunchMode.externalApplication);
             
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Opening Payment App... Please enter details manually upon return.')),
               );
             }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not find a supporting UPI app.')),
              );
            }
          }
        } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error launching UPI: $e')),
             );
           }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid UPI QR Code.')),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 2. BACKEND SAVE LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      
      if (_paymentMethod == 'upi' && _selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a bank account for UPI payment.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final apiService = ApiService();
        final authState = ref.read(authProvider);
        
        if (authState.token == null || authState.user == null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication error. Please login again.')));
             return;
        }

        final token = authState.token!;
        final user = authState.user!;
        
        await apiService.addExpense(
          token: token,
          description: _descriptionController.text,
          category: _category,
          amount: double.parse(_amountController.text),
          currency: user.preferredCurrency ?? 'INR',
          paymentMethod: _paymentMethod,
          bankAccountId: _selectedBankAccountId,
          recipientInfo: _recipientController.text.isNotEmpty ? _recipientController.text : null,
        );

        ref.read(dashboardProvider.notifier).fetchDashboardData();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close the screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense Saved Successfully!')),
          );
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving expense: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. UI BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bankAccounts = ref.watch(dashboardProvider).bankAccounts;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SCAN QR BUTTON ---
              GestureDetector(
                onTap: _scanQRCode,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scan UPI QR & Pay",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Launches your payment app directly",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  prefixText: '₹ ', 
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Payment Method Toggle
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'upi', label: Text('UPI / Bank'), icon: Icon(Icons.account_balance_wallet)),
                  ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.money)),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _paymentMethod = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Bank Account Selection
              if (_paymentMethod == 'upi' || bankAccounts.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedBankAccountId,
                  decoration: InputDecoration(
                    labelText: _paymentMethod == 'upi' ? 'Pay From (Required)' : 'Pay From (Optional)',
                    helperText: _paymentMethod == 'cash' 
                        ? 'Select to log as withdrawal' 
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  items: bankAccounts.map((BankAccount account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text('${account.bankName} (${account.accountType})'),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedBankAccountId = newValue),
                  validator: (value) {
                    if (_paymentMethod == 'upi' && value == null) {
                      return 'Select a bank account for UPI';
                    }
                    return null;
                  },
                ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Food', 'Transport', 'Utilities', 'Entertainment', 'Health', 'Other']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _category = newValue!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Payee Info (UPI ID / Name) [Optional]',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 32),
              
              // --- SAVE BUTTON ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(_paymentMethod == 'cash' ? 'Save Cash Expense' : 'Save Expense Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}