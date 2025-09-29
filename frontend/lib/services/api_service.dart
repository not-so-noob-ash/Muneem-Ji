import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/user_model.dart';
import '../models/bank_account_model.dart';

class ApiService {
  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    // CORRECTED: The token URL should not have the /users prefix.
    final response = await http.post(
      Uri.parse('$apiBaseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to login.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/users/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to register.'};
      throw Exception(errorData['detail'] ?? 'An unknown error occurred.');
    }
  }

  Future<User> getMe(String token) async {
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

  // --- Onboarding ---
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
        'balance': balance.toString(), // Send balance as a string for precision
        'currency': currency,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Failed to add bank account.'};
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
}

