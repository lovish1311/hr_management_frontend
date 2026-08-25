import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static String? _token;
  static String? _userEmail;
  static String? _userRole;
  static int? _employeeId;

  static const String _kToken = 'auth_token';
  static const String _kEmail = 'auth_email';
  static const String _kRole = 'auth_role';
  static const String _kEmpId = 'auth_employee_id';

  /// Initialize and hydrate auth state from persistent storage on startup
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userEmail = prefs.getString(_kEmail);
    _userRole = prefs.getString(_kRole);
    _employeeId = prefs.getInt(_kEmpId);
  }

  static Future<void> setAuth({
    required String token,
    String? email,
    String? role,
    int? employeeId,
  }) async {
    _token = token;
    _userEmail = email;
    _userRole = role;
    _employeeId = employeeId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (email != null) await prefs.setString(_kEmail, email);
    if (role != null) await prefs.setString(_kRole, role);
    if (employeeId != null) await prefs.setInt(_kEmpId, employeeId);
  }

  static String? get token => _token;
  static String? get userEmail => _userEmail;
  static String? get userRole => _userRole;
  static int? get employeeId => _employeeId;

  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static bool get isSuperAdmin {
    final r = (_userRole ?? '').toUpperCase();
    return r == 'ROLE_SUPER_ADMIN' || r == 'SUPER_ADMIN' || r == 'ADMIN';
  }

  static bool get isHr {
    final r = (_userRole ?? '').toUpperCase();
    return isSuperAdmin || r == 'ROLE_HR' || r == 'HR';
  }

  static bool get isManager {
    final r = (_userRole ?? '').toUpperCase();
    return isHr || r == 'ROLE_MANAGER' || r == 'MANAGER';
  }

  static Map<String, String> get authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<void> clear() async {
    _token = null;
    _userEmail = null;
    _userRole = null;
    _employeeId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kEmpId);
  }
}
