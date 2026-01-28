import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_summary_model.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import 'add_bank_account_screen.dart';
import 'add_income_screen.dart';
import 'add_budget_screen.dart';
import 'add_expense_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 36),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authNotifier.logout(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
        },
        child: dashboardState.isLoading && dashboardState.summary == null
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.errorMessage != null
                ? Center(child: Text('Error: ${dashboardState.errorMessage}'))
                : _buildDashboardContent(context, ref, dashboardState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, DashboardState state) {
    // Check if onboarding steps are done
    final bool hasBankAccounts = state.hasBankAccounts;
    final bool hasIncome = state.hasIncome;
    final bool hasBudgets = state.hasBudgets;
    final bool isSetupComplete = hasBankAccounts && hasIncome && hasBudgets;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. Onboarding Setup Guide (Only shows if incomplete) ---
        if (!isSetupComplete)
          _SetupGuide(
            hasBankAccounts: hasBankAccounts,
            hasIncome: hasIncome,
            hasBudgets: hasBudgets,
          ),

        // --- 2. Net Worth Card ---
        hasBankAccounts
            ? _NetWorthCard(summary: state.summary!)
            : _EmptyStateCard(
                title: 'Calculate Your Net Worth',
                subtitle: 'Add your first bank account to get started.',
                buttonText: 'Add Bank Account',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBankAccountScreen()),
                ),
              ),
        
        const SizedBox(height: 24),
        
        // --- 3. Budgets Section ---
        if (hasBankAccounts && !hasBudgets)
           _EmptyStateCard(
                title: 'Track Your Spending',
                subtitle: 'Set up budgets to manage your financial goals.',
                buttonText: 'Add a Budget',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
                ),
              ),
        
        // **FIX: Actually show the budgets if they exist**
        if (hasBudgets) ...[
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text(
                'Your Budgets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               TextButton(onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
                  );
               }, child: const Text("Add New"))
             ],
           ),
           const SizedBox(height: 8),
           // Display list of budgets
           ...state.budgets.map((budget) => _BudgetCard(budget: budget, currency: state.summary?.currency ?? '')),
        ],

        const SizedBox(height: 24),

        // --- 4. Recent Transactions Section ---
        if (hasBankAccounts) ...[
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          if (state.personalExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Center(child: Text('No personal expenses recorded yet.', style: TextStyle(color: Colors.grey))),
            )
          else
            ...state.personalExpenses.map((expense) => _TransactionCard(expense: expense, currency: state.summary?.currency ?? '')),
        ],
        
        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }
}

// --- Helper Widgets ---

// 1. Budget Card Widget
class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final String currency;

  const _BudgetCard({required this.budget, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(budget.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text(
                  '$currency ${budget.amount.toStringAsFixed(0)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar placeholder (since we don't have spent vs budget logic in backend yet)
            LinearProgressIndicator(
              value: 0.0, // TODO: Connect to actual spending data
              backgroundColor: Theme.of(context).dividerColor,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: Text("0% Used", style: TextStyle(fontSize: 10, color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}

// 2. Transaction Card Widget
class _TransactionCard extends StatelessWidget {
  final Expense expense;
  final String currency;

  const _TransactionCard({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.receipt_long),
        ),
        title: Text(expense.description),
        subtitle: Text(expense.category),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-$currency ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            Text(
              expense.paymentMethod.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupGuide extends StatelessWidget {
  final bool hasBankAccounts;
  final bool hasIncome;
  final bool hasBudgets;

  const _SetupGuide({
    required this.hasBankAccounts,
    required this.hasIncome,
    required this.hasBudgets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to Muneem Ji!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Complete your setup to unlock your full financial dashboard."),
            const SizedBox(height: 16),
            _buildStep(context,
              title: '1. Add a Bank Account',
              isComplete: hasBankAccounts,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBankAccountScreen())),
            ),
            _buildStep(context,
              title: '2. Add an Income Source',
              isComplete: hasIncome,
              onTap: () {
                if (!hasBankAccounts) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a bank account first!')));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddIncomeScreen()));
                }
              },
            ),
             _buildStep(context,
              title: '3. Set Your First Budget',
              isComplete: hasBudgets,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBudgetScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, {required String title, required bool isComplete, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isComplete ? Icons.check_circle : Icons.circle_outlined,
        color: isComplete ? Colors.greenAccent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        title, 
        style: TextStyle(
          decoration: isComplete ? TextDecoration.lineThrough : null,
          color: isComplete ? Colors.grey : null
        )
      ),
      onTap: isComplete ? null : onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final DashboardSummary summary;
  const _NetWorthCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('NET me', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(
              '${summary.currency} ${summary.netWorth.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}