import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static String? _token;
  static String? _userEmail;
  static String? _userRole;
  static String? _userSystemRole;
  static int? _employeeId;
  static List<String> _authorities = [];

  static const String _kToken = 'auth_token';
  static const String _kEmail = 'auth_email';
  static const String _kRole = 'auth_role';
  static const String _kSystemRole = 'auth_system_role';
  static const String _kEmpId = 'auth_employee_id';
  static const String _kAuthorities = 'auth_authorities';

  /// Initialize and hydrate auth state from persistent storage on startup
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userEmail = prefs.getString(_kEmail);
    _userRole = prefs.getString(_kRole);
    _userSystemRole = prefs.getString(_kSystemRole);
    _employeeId = prefs.getInt(_kEmpId);
    _authorities = prefs.getStringList(_kAuthorities) ?? [];
  }

  static Future<void> setAuth({
    required String token,
    String? email,
    String? role,
    String? systemRole,
    int? employeeId,
    List<String>? authorities,
  }) async {
    _token = token;
    _userEmail = email;
    _userRole = role;
    _userSystemRole = systemRole;
    _employeeId = employeeId;
    if (authorities != null) {
      _authorities = authorities.map((a) => a.toUpperCase()).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (email != null) await prefs.setString(_kEmail, email);
    if (role != null) await prefs.setString(_kRole, role);
    if (systemRole != null) await prefs.setString(_kSystemRole, systemRole);
    if (employeeId != null) await prefs.setInt(_kEmpId, employeeId);
    if (authorities != null) {
      await prefs.setStringList(_kAuthorities, _authorities);
    }
  }

  static String? get token => _token;
  static String? get userEmail => _userEmail;
  static String? get userRole => _userRole;
  static String? get userSystemRole => _userSystemRole;
  static int? get employeeId => _employeeId;
  static List<String> get authorities => List.unmodifiable(_authorities);

  static bool hasAuthority(String authority) =>
      _authorities.contains(authority.toUpperCase());

  static bool get canManagePayroll =>
      isAdmin || isHr || hasAuthority('PAYROLL_MANAGE');

  static bool get canManageSalaryStructure =>
      isAdmin || hasAuthority('SALARY_STRUCTURE_MANAGE');

  static bool get canApproveAllLeaves =>
      isAdmin || isHr || hasAuthority('LEAVE_APPROVE_ALL');

  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Super Admin holds the highest master administrative control tier (can manage Admins)
  static bool get isSuperAdmin {
    final r = (_userRole ?? '').toUpperCase();
    final s = (_userSystemRole ?? '').toUpperCase();
    return r == 'ROLE_SUPER_ADMIN' || r == 'SUPER_ADMIN' || s == 'SUPER_ADMIN';
  }

  /// Admin holds full operational permissions across modules (Leaves, Payroll, Attendance, Games, Employees)
  static bool get isAdmin {
    if (isSuperAdmin) return true;
    final r = (_userRole ?? '').toUpperCase();
    final s = (_userSystemRole ?? '').toUpperCase();
    return r == 'ROLE_ADMIN' || r == 'ADMIN' || s == 'ADMIN' || _authorities.contains('ROLE_ADMIN');
  }

  static bool get isHr {
    final r = (_userRole ?? '').toUpperCase();
    return isAdmin || r == 'ROLE_HR' || r == 'HR';
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
    if (_employeeId != null) {
      headers['X-Employee-Id'] = _employeeId.toString();
    }
    return headers;
  }

  static Future<void> clear() async {
    _token = null;
    _userEmail = null;
    _userRole = null;
    _userSystemRole = null;
    _employeeId = null;
    _authorities = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kSystemRole);
    await prefs.remove(_kEmpId);
    await prefs.remove(_kAuthorities);
  }
}

