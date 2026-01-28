import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/user_model.dart';
import '../models/bank_account_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/budget_model.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/group_data_models.dart';

class ApiService {
  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    // CORRECTED: Removed '/users' prefix to match backend
    final response = await http.post(
      Uri.parse('$apiBaseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    return _handleAuthResponse(response);
  }

  Future<void> register(String email, String password) async {
    // CORRECTED: Removed '/users' prefix to match backend
    final response = await http.post(
      Uri.parse('$apiBaseUrl/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to register.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<User> getMe(String token) async {
    // This remains '/users/me' because it is explicitly defined that way in user.py
    final response = await http.get(
      Uri.parse('$apiBaseUrl/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch user profile.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<User> updateProfile({
    required String token,
    required String fullName,
    required String upiId,
    required String preferredCurrency,
  }) async {
    // This remains '/users/me'
    final response = await http.put(
      Uri.parse('$apiBaseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'full_name': fullName,
        'upi_id': upiId,
        'preferred_currency': preferredCurrency,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to update profile.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  // --- Personal Finance ---
  Future<void> addBankAccount({
    required String token,
    required String bankName,
    required String accountType,
    required double balance,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/bank-accounts'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'bank_name': bankName,
        'account_type': accountType,
        'balance': balance.toString(),
        'currency': currency,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to add bank account.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<void> addIncome({
    required String token,
    required int bankAccountId,
    required String source,
    required double amount,
    required String recurrence,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/income'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'bank_account_id': bankAccountId,
        'source': source,
        'amount': amount.toString(),
        'recurrence': recurrence,
      }),
    );
     if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to add income.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<void> addBudget({
    required String token,
    required String title,
    required String category,
    required double amount,
    required String recurrence,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/budgets'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'category': category,
        'amount': amount.toString(),
        'recurrence': recurrence,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to add budget.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<void> addExpense({
    required String token,
    required String description,
    required String category,
    required double amount,
    required String currency,
    required String paymentMethod,
    int? bankAccountId,
    String? recipientInfo,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/expenses'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'description': description,
        'category': category,
        'amount': amount.toString(),
        'currency': currency,
        'payment_method': paymentMethod,
        'bank_account_id': bankAccountId,
        'recipient_info': recipientInfo,
        'notes': notes,
        'transaction_date': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to add expense.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }
  
  // --- Dashboard Data ---

  Future<DashboardSummary> getDashboardSummary({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/dashboard/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return DashboardSummary.fromJson(json.decode(response.body));
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch dashboard summary.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<List<BankAccount>> getBankAccounts({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/bank-accounts'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => BankAccount.fromJson(item)).toList();
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch bank accounts.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<List<Budget>> getBudgets({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/budgets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Budget.fromJson(item)).toList();
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch budgets.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<List<Income>> getIncomes({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/income'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Income.fromJson(item)).toList();
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch incomes.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }
  
  Future<List<Expense>> getPersonalExpenses({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/expenses'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Expense.fromJson(item)).toList();
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch personal expenses.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  // --- GROUPS ---

  Future<List<Group>> getGroups({required String token}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/groups'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Group.fromJson(item)).toList();
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to fetch groups.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<void> createGroup({required String token, required String name}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/groups'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'name': name}),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to create group.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  // --- NEW: GROUP DETAILS & EXPENSES ---

  Future<List<GroupBalance>> getGroupBalance({required String token, required int groupId}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/groups/$groupId/balance'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => GroupBalance.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch group balance');
    }
  }

  Future<List<GroupExpense>> getGroupExpenses({required String token, required int groupId}) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/groups/$groupId/expenses'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => GroupExpense.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch group expenses');
    }
  }

  // Helper for Auth response
  Map<String, dynamic> _handleAuthResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Request failed.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }
}