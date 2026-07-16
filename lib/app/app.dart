import 'package:flutter/material.dart';
import 'package:hr_management/app/router.dart';
import 'package:hr_management/app/theme.dart';

// Package: hr_management

class HRManagementApp extends StatelessWidget {
  const HRManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HR Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: AppRouter.routes,
    );
  }
}
