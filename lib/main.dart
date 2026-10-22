import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hr_management/app/app.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/services/push_notification_client_service.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }
  await AuthStorage.init();
  await ThemeManager.instance.initialize();
  
  // Initialize Push Notifications (FCM) asynchronously without blocking app rendering
  PushNotificationClientService.instance.initialize().catchError((e) {
    debugPrint('[PushNotification] Init skipped/failed: $e');
  });

  runApp(
    const ProviderScope(
      child: HRManagementApp(),
    ),
  );
}
