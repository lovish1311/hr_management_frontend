import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/network/api_client.dart';
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

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to dispatch verification code';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': token,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to reset password';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> activateAccount({
    required String activationKey,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/activate');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'activationKey': activationKey,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to activate account';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> sendEmployeeCredentials(String employeeId, {String? token}) async {
    final url = Uri.parse('$baseUrl/employees/$employeeId/send-credentials');
    final response = await ApiClient.post(url);
    if (response.statusCode != 200) {
      String msg = 'Failed to send credentials';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

