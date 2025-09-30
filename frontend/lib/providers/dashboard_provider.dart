import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_summary_model.dart';
import '../models/bank_account_model.dart';
import '../models/budget_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// State for the dashboard
class DashboardState {
  final bool isLoading;
  final DashboardSummary? summary;
  final List<BankAccount> bankAccounts;
  final List<Budget> budgets;
  final String? errorMessage;

  DashboardState({
    this.isLoading = true,
    this.summary,
    this.bankAccounts = const [],
    this.budgets = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    List<BankAccount>? bankAccounts,
    List<Budget>? budgets,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      budgets: budgets ?? this.budgets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier for the dashboard
class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;
  final String _token;

  DashboardNotifier(this._apiService, this._token) : super(DashboardState()) {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Fetch all data in parallel
      final results = await Future.wait([
        _apiService.getDashboardSummary(token: _token),
        _apiService.getBankAccounts(token: _token),
        _apiService.getBudgets(token: _token),
      ]);

      state = state.copyWith(
        isLoading: false,
        summary: results[0] as DashboardSummary,
        bankAccounts: results[1] as List<BankAccount>,
        budgets: results[2] as List<Budget>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Provider definition
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ApiService();
  final token = ref.watch(authProvider).token ?? '';
  return DashboardNotifier(apiService, token);
});
