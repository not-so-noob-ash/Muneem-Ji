import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_account_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class OnboardingState {
  final List<BankAccount> bankAccounts;
  final bool isLoading;
  final String? errorMessage;

  OnboardingState({
    this.bankAccounts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    List<BankAccount>? bankAccounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      bankAccounts: bankAccounts ?? this.bankAccounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ApiService _apiService;
  final String _token;

  OnboardingNotifier(this._apiService, this._token) : super(OnboardingState());

  Future<bool> addBankAccount({
    required String bankName,
    required String accountType,
    required double balance,
    required String currency,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.addBankAccount(
        token: _token,
        bankName: bankName,
        accountType: accountType,
        balance: balance,
        currency: currency,
      );
      await fetchBankAccounts();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> fetchBankAccounts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final accounts = await _apiService.getBankAccounts(token: _token);
      state = state.copyWith(isLoading: false, bankAccounts: accounts);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
  
  Future<bool> addIncome({
    required int bankAccountId,
    required String source,
    required double amount,
    required String recurrence,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.addIncome(
        token: _token,
        bankAccountId: bankAccountId,
        source: source,
        amount: amount,
        recurrence: recurrence,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addBudget({
    required String title,
    required String category,
    required double amount,
    required String recurrence,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.addBudget(
        token: _token,
        title: title,
        category: category,
        amount: amount,
        recurrence: recurrence,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  // Correctly and safely watch the authProvider for changes
  final token = ref.watch(authProvider.select((state) => state.token));
  return OnboardingNotifier(ApiService(), token ?? '');
});

