import 'package:flutter/material.dart';
import 'package:hr_management/app/app.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.init();
  await ThemeManager.instance.initialize();
  runApp(const HRManagementApp());
}
