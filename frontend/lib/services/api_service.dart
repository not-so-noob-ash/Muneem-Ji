import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ApiService {
  Future<Map<String, dynamic>> register(String email, String password) async {
    final url = Uri.parse('$apiBaseUrl/users/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      final responseBody = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$apiBaseUrl/token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'token': responseBody['access_token']};
      } else {
        return {'success': false, 'message': responseBody['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  // NEW METHOD: Get the current user's profile
  Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('$apiBaseUrl/users/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['detail'] ?? 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }

  // NEW METHOD: Update the user's profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String upiId,
    required String preferredCurrency,
  }) async {
    final url = Uri.parse('$apiBaseUrl/users/me');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'full_name': fullName,
          'upi_id': upiId,
          'preferred_currency': preferredCurrency,
        }),
      );
      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['detail'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to the server.'};
    }
  }
}

