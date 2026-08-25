import 'package:flutter/material.dart';
import 'package:hr_management/app/app.dart';
import 'package:hr_management/core/services/auth_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.init();
  runApp(const HRManagementApp());
}
