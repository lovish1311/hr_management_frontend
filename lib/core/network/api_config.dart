import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _customUrl = String.fromEnvironment('BASE_URL');

  /// Centralized backend URL.
  /// - Web: Dynamically uses current browser window origin (e.g. https://*.trycloudflare.com or http://localhost:8080)
  /// - Android / iOS Mobile: Uses custom BASE_URL or falls back to http://localhost:8080
  static String get baseUrl {
    if (_customUrl.isNotEmpty) return _customUrl;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file:') && origin != 'null') {
        final host = Uri.base.host;
        if (host == 'localhost' || host == '127.0.0.1') {
          return 'http://localhost:8080';
        }
        return origin;
      }
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://localhost:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  static String get wsUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return 'wss://${base.substring(8)}';
    } else if (base.startsWith('http://')) {
      return 'ws://${base.substring(7)}';
    }
    return 'ws://$base';
  }
}
