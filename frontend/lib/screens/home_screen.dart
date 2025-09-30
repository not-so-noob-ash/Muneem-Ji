import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import 'add_bank_account_screen.dart';
import '../models/dashboard_summary_model.dart';
// We will create the other "add" screens later
// import 'add_budget_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);

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
        onRefresh: () => ref.read(dashboardProvider.notifier).fetchDashboardData(),
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.errorMessage != null
                ? Center(child: Text('Error: ${dashboardState.errorMessage}'))
                : _buildDashboardContent(context, dashboardState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Add Personal Expense flow
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardState state) {
    final bool hasBankAccounts = state.bankAccounts.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Net Worth Card ---
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
        
        // --- TODO: Add other widgets like Budgets and Recent Transactions ---
        // For now, we'll just show a placeholder if accounts exist
        if(hasBankAccounts)
          Text(
            'Your Financial Hub',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

// --- Helper Widgets ---

class _NetWorthCard extends StatelessWidget {
  final DashboardSummary summary;
  const _NetWorthCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('NET WORTH', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
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

