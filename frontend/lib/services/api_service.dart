import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';

// A Riverpod provider that creates a single instance of our ApiService
// that can be accessed from anywhere in the app.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  // Method for user registration
  // It sends a POST request to the /register endpoint.
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/users/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      // If the server returns a 201 CREATED response,
      // then parse the JSON and return it.
      return jsonDecode(response.body);
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception with the error message.
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // Method for user login
  // It sends a POST request to the /token endpoint.
  Future<String> login(String email, String password) async {
    // NOTE: The backend's /token endpoint expects OAuth2-style form data, not JSON.
    final response = await http.post(
      Uri.parse('$apiBaseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response,
      // parse the JSON, extract the token, and return it.
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
