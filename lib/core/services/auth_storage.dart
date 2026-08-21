class AuthStorage {
  static String? _token;
  static String? _userEmail;
  static String? _userRole;

  static void setAuth({required String token, String? email, String? role}) {
    _token = token;
    _userEmail = email;
    _userRole = role;
  }

  static String? get token => _token;
  static String? get userEmail => _userEmail;
  static String? get userRole => _userRole;

  static Map<String, String> get authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static void clear() {
    _token = null;
    _userEmail = null;
    _userRole = null;
  }
}
