import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:hr_management/core/network/api_config.dart';
import 'package:hr_management/core/services/auth_storage.dart';

/// Top-level background message handler required by FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received message id: ${message.messageId}, data: ${message.data}');
}

class PushNotificationClientService {
  static final PushNotificationClientService instance = PushNotificationClientService._internal();
  PushNotificationClientService._internal();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initializes FCM, requests permissions, and wires foreground/tap listeners
  Future<void> initialize({Function(RemoteMessage)? onNotificationOpened}) async {
    if (_initialized) return;

    if (kIsWeb) {
      debugPrint('[PushNotification] Web platform detected; FCM background push is disabled without firebase-messaging-sw.js');
      _initialized = true;
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request user permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[PushNotification] Permission status: ${settings.authorizationStatus}');

      // 2. Register background handler (Android / iOS only - Web uses firebase-messaging-sw.js)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // 3. Obtain registration token safely
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[PushNotification] Device token obtained: ${_fcmToken != null ? "YES" : "NO"}');
      } catch (tokenErr) {
        debugPrint('[PushNotification] getToken() failed: $tokenErr');
      }

      // 4. Send token to backend if user is already authenticated
      if (_fcmToken != null && AuthStorage.token != null) {
        await syncTokenWithBackend(_fcmToken!);
      }

      // 5. Listen to token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (AuthStorage.token != null) {
          syncTokenWithBackend(newToken);
        }
      });

      // 6. Handle notification tapped while app was in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[PushNotification] Notification opened from background: ${message.data}');
        if (onNotificationOpened != null) {
          onNotificationOpened(message);
        }
      });

      // 7. Check if app was opened directly from a terminated state notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && onNotificationOpened != null) {
        onNotificationOpened(initialMessage);
      }

      // 8. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushNotification] Foreground message: ${message.notification?.title} - ${message.notification?.body}');
      });

      _initialized = true;
    } catch (e, stack) {
      debugPrint('[PushNotification] Initialization error: $e\n$stack');
    }
  }

  /// Syncs FCM device token with the backend
  Future<void> syncTokenWithBackend(String token) async {
    final authToken = AuthStorage.token;
    if (authToken == null || authToken.isEmpty) return;

    final deviceType = kIsWeb
        ? 'WEB'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID');

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/devices/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'deviceType': deviceType,
          'deviceName': kIsWeb ? 'Web Browser' : defaultTargetPlatform.name,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[PushNotification] Device token synced successfully with backend');
      } else {
        debugPrint('[PushNotification] Token sync failed HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[PushNotification] Network error while syncing device token: $e');
    }
  }

  /// Unregisters FCM token from backend upon user logout
  Future<void> unregisterCurrentToken() async {
    if (_fcmToken == null || AuthStorage.token == null) return;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/devices/unregister?token=$_fcmToken');
      await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${AuthStorage.token}',
        },
      );
      debugPrint('[PushNotification] Device token unregistered from backend');
    } catch (e) {
      debugPrint('[PushNotification] Error unregistering token: $e');
    }
  }
}
