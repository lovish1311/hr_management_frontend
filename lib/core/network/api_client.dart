import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/services/permission_socket_service.dart';

/// Centralized HTTP client and request dispatcher for the entire application.
/// 
/// Features:
/// 1. Automatic base URL resolution and header injection (`AuthStorage.authHeaders`).
/// 2. Global 401 Unauthorized interceptor:
///    - Safely clears expired authentication tokens from memory & SharedPreferences.
///    - Seamlessly redirects the user back to the `/login` route.
///    - Displays a non-intrusive warning SnackBar.
/// 3. Debounce mechanism to prevent multiple redirects or dialog cascades when
///    several asynchronous API requests return 401 simultaneously.
class ApiClient {
  static final _ApiClientHandler _handler = _ApiClientHandler();
  static bool _isHandling401 = false;

  /// Underlying http.Client instance with interceptor support
  static http.Client get client => _handler;

  /// Helper to convert relative or absolute URLs to a canonical Uri
  static Uri resolveUri(dynamic url) {
    if (url is Uri) return url;
    final pathOrUrl = url.toString();
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Uri.parse(pathOrUrl);
    }
    final base = ApiConfig.baseUrl;
    final cleanPath = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return Uri.parse('$base$cleanPath');
  }

  /// Merges default auth headers with caller-provided headers
  static Map<String, String> mergeHeaders([Map<String, String>? customHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    headers.addAll(AuthStorage.authHeaders);
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Executes an HTTP GET request
  static Future<http.Response> get(dynamic url, {Map<String, String>? headers}) async {
    final uri = resolveUri(url);
    final response = await _handler.get(uri, headers: headers);
    return response;
  }

  /// Executes an HTTP POST request
  static Future<http.Response> post(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final uri = resolveUri(url);
    final response = await _handler.post(
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    return response;
  }

  /// Executes an HTTP PUT request
  static Future<http.Response> put(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final uri = resolveUri(url);
    final response = await _handler.put(
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    return response;
  }

  /// Executes an HTTP DELETE request
  static Future<http.Response> delete(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final uri = resolveUri(url);
    final response = await _handler.delete(
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    return response;
  }

  /// Executes an HTTP PATCH request
  static Future<http.Response> patch(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final uri = resolveUri(url);
    final response = await _handler.patch(
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    return response;
  }

  /// Centralized session termination and UI redirect upon receiving a 401 Unauthorized
  static void handleUnauthorized(String endpointPath) {
    if (!AuthStorage.isAuthenticated) return;
    if (_isHandling401) return;

    _isHandling401 = true;
    debugPrint('[ApiClient] 401 Unauthorized encountered on $endpointPath. Evicting session and navigating to /login.');

    AuthStorage.clear();

    final navState = PermissionSocketService.navigatorKey.currentState;
    if (navState != null) {
      navState.pushNamedAndRemoveUntil('/login', (route) => false);

      final context = PermissionSocketService.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock_clock_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Your session has expired. Please sign in again.')),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    // Debounce for 3 seconds to avoid cascade triggers
    Future.delayed(const Duration(seconds: 3), () {
      _isHandling401 = false;
    });
  }
}

class _ApiClientHandler extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Automatically attach authentication headers
    AuthStorage.authHeaders.forEach((key, value) {
      if (!request.headers.containsKey(key)) {
        request.headers[key] = value;
      }
    });

    if (!request.headers.containsKey('Content-Type') &&
        (request.method == 'POST' || request.method == 'PUT' || request.method == 'PATCH')) {
      request.headers['Content-Type'] = 'application/json';
    }

    final response = await _inner.send(request);

    // 2. Intercept 401 Unauthorized
    if (response.statusCode == 401) {
      final path = request.url.path;
      if (!path.contains('/auth/login') &&
          !path.contains('/auth/forgot-password') &&
          !path.contains('/auth/reset-password') &&
          !path.contains('/auth/activate')) {
        ApiClient.handleUnauthorized(path);
      }
    }

    return response;
  }
}
