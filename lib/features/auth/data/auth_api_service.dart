import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/network/api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// High-fidelity Account Status DTO matching backend `/api/auth/account-status` contract.
class AccountStatus {
  final String email;
  final String status; // PENDING_ACTIVATION, ACTIVE, DEACTIVATED, NOT_FOUND
  final bool isActivated;
  final String? firstName;
  final String message;

  const AccountStatus({
    required this.email,
    required this.status,
    required this.isActivated,
    this.firstName,
    required this.message,
  });

  bool get isPendingActivation => status == 'PENDING_ACTIVATION';
  bool get isDeactivated => status == 'DEACTIVATED';
  bool get isActive => status == 'ACTIVE';
  bool get isNotFound => status == 'NOT_FOUND';

  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    return AccountStatus(
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NOT_FOUND',
      isActivated: json['isActivated'] == true,
      firstName: json['firstName']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'status': status,
    'isActivated': isActivated,
    'firstName': firstName,
    'message': message,
  };
}

/// Rich exception representing structured backend auth failures.
class AuthException implements Exception {
  final String message;
  final int statusCode;
  final String? code; // e.g. PENDING_ACTIVATION, DEACTIVATED, BAD_CREDENTIALS

  const AuthException(this.message, {this.statusCode = 400, this.code});

  bool get isPendingActivation => code == 'PENDING_ACTIVATION' || statusCode == 423;
  bool get isDeactivated => code == 'DEACTIVATED' || statusCode == 403;
  bool get isBadCredentials => code == 'BAD_CREDENTIALS' || statusCode == 401;

  @override
  String toString() => message;
}

class AuthApiService {
  static String get baseUrl => "${ApiConfig.baseUrl}/api";

  /// High-speed in-memory cache to prevent redundant HTTP roundtrips on repeated email checks
  static final Map<String, AccountStatus> _statusCache = {};

  /// Retrieves indexed account lifecycle state (`ACTIVE`, `PENDING_ACTIVATION`, `DEACTIVATED`, `NOT_FOUND`).
  static Future<AccountStatus> getAccountStatus(String email, {bool forceRefresh = false}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email is required');
    }

    if (!forceRefresh && _statusCache.containsKey(cleanEmail)) {
      return _statusCache[cleanEmail]!;
    }

    final url = Uri.parse('$baseUrl/auth/account-status?email=${Uri.encodeComponent(cleanEmail)}');
    http.Response response;
    try {
      response = await http.get(url);
    } catch (e) {
      throw const AuthException('Unable to verify account status. Please check your network connection.');
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = AccountStatus.fromJson(data);
        _statusCache[cleanEmail] = status;
        return status;
      } catch (_) {
        throw const AuthException('Server returned an invalid account status format.');
      }
    } else {
      String msg = 'Failed to verify account status';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw AuthException(msg, statusCode: response.statusCode);
    }
  }

  /// Clears the in-memory cache, optionally for a specific email upon activation or status update.
  static void clearStatusCache([String? email]) {
    if (email != null) {
      _statusCache.remove(email.trim().toLowerCase());
    } else {
      _statusCache.clear();
    }
  }

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
          'email': email.trim(),
          'password': password,
        }),
      );
    } catch (e) {
      throw AuthException('Unable to connect to server at $baseUrl. Please ensure the backend is running.', statusCode: 503);
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const AuthException('Server returned an invalid response format.');
      }
    }

    // Parse structured error responses from backend GlobalExceptionHandler
    String? message;
    String? code;
    try {
      if (response.body.trim().isNotEmpty) {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          message = errorData['message']?.toString();
          code = errorData['code']?.toString();
        }
      }
    } catch (_) {}

    if (response.statusCode == 423 || code == 'PENDING_ACTIVATION') {
      throw AuthException(
        message ?? 'Account pending activation. Enter your activation key to set your password.',
        statusCode: 423,
        code: 'PENDING_ACTIVATION',
      );
    } else if (response.statusCode == 403) {
      throw AuthException(
        message ?? 'This account has been deactivated. Please contact HR.',
        statusCode: 403,
        code: 'DEACTIVATED',
      );
    } else if (response.statusCode == 401) {
      throw const AuthException(
        'Invalid email or password. Please try again.',
        statusCode: 401,
        code: 'BAD_CREDENTIALS',
      );
    } else if (response.statusCode == 409) {
      throw AuthException(
        message ?? 'Conflict occurred. Please verify your account state.',
        statusCode: 409,
      );
    } else {
      throw AuthException(
        message ?? 'Authentication failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
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
          'email': email.trim(),
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'department': department,
          'role': role,
        }),
      );
    } catch (e) {
      throw AuthException('Unable to connect to server at $baseUrl. Please ensure the backend is running.', statusCode: 503);
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const AuthException('Server returned an invalid response format.');
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
      throw AuthException(message ?? 'Registration failed (HTTP ${response.statusCode}).', statusCode: response.statusCode);
    }
  }

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to dispatch verification code';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw AuthException(msg, statusCode: response.statusCode);
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
        'email': email.trim(),
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
      throw AuthException(msg, statusCode: response.statusCode);
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
        'activationKey': activationKey.trim(),
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to activate account';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'].toString();
      } catch (_) {}
      throw AuthException(msg, statusCode: response.statusCode);
    }
    try {
      final res = jsonDecode(response.body) as Map<String, dynamic>;
      final activatedEmail = res['email']?.toString();
      if (activatedEmail != null) {
        clearStatusCache(activatedEmail);
      }
      return res;
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
      throw AuthException(msg, statusCode: response.statusCode);
    }
  }
}
