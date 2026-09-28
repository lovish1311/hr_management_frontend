import 'package:hr_management/core/network/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  static String get baseUrl => "${ApiConfig.baseUrl}/api";

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Unable to connect to server at $baseUrl. Please ensure the backend is running.');
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Server returned an invalid response format.');
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Invalid email or password. Please try again.');
    } else {
      String? message;
      try {
        if (response.body.trim().isNotEmpty) {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            message = errorData['message']?.toString();
          }
        }
      } catch (_) {}
      throw Exception(message ?? 'Authentication failed (HTTP ${response.statusCode}).');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String department,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'department': department,
          'role': role,
        }),
      );
    } catch (e) {
      throw Exception('Unable to connect to server at $baseUrl. Please ensure the backend is running.');
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Server returned an invalid response format.');
      }
    } else {
      String? message;
      try {
        if (response.body.trim().isNotEmpty) {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            message = errorData['message']?.toString();
          }
        }
      } catch (_) {}
      throw Exception(message ?? 'Registration failed (HTTP ${response.statusCode}).');
    }
  }
}
