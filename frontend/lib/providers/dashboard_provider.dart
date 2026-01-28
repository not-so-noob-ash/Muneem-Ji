import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_summary_model.dart';
import '../models/bank_account_model.dart';
import '../models/budget_model.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// State for the dashboard
class DashboardState {
  final bool isLoading;
  final DashboardSummary? summary;
  final List<BankAccount> bankAccounts;
  final List<Budget> budgets;
  final List<Income> incomes;
  final List<Expense> personalExpenses;
  final String? errorMessage;

  DashboardState({
    this.isLoading = true,
    this.summary,
    this.bankAccounts = const [],
    this.budgets = const [],
    this.incomes = const [],
    this.personalExpenses = const [],
    this.errorMessage,
  });

  // --- THESE WERE MISSING ---
  bool get hasIncome => incomes.isNotEmpty;
  bool get hasBudgets => budgets.isNotEmpty;
  bool get hasBankAccounts => bankAccounts.isNotEmpty;

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    List<BankAccount>? bankAccounts,
    List<Budget>? budgets,
    List<Income>? incomes,
    List<Expense>? personalExpenses,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      budgets: budgets ?? this.budgets,
      incomes: incomes ?? this.incomes,
      personalExpenses: personalExpenses ?? this.personalExpenses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;
  final String _token;

  DashboardNotifier(this._apiService, this._token) : super(DashboardState()) {
    if (_token.isNotEmpty) {
      fetchDashboardData();
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final results = await Future.wait([
        _apiService.getDashboardSummary(token: _token),
        _apiService.getBankAccounts(token: _token),
        _apiService.getBudgets(token: _token),
        _apiService.getIncomes(token: _token),
        _apiService.getPersonalExpenses(token: _token),
      ]);

      state = state.copyWith(
        isLoading: false,
        summary: results[0] as DashboardSummary,
        bankAccounts: results[1] as List<BankAccount>,
        budgets: results[2] as List<Budget>,
        incomes: results[3] as List<Income>,
        personalExpenses: results[4] as List<Expense>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ApiService();
  final token = ref.watch(authProvider).token ?? '';
  return DashboardNotifier(apiService, token);
});