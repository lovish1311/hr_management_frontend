import 'package:flutter/material.dart';
import 'package:hr_management/app/theme.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_http_overrides.dart';

class TestAppWrapper {
  static Future<void> setup({bool isSuperAdmin = true, int employeeId = 1}) async {
    MockHttpOverrides.install();
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock-jwt-token',
      'auth_email': isSuperAdmin ? 'admin@company.com' : 'employee@company.com',
      'auth_role': isSuperAdmin ? 'ROLE_SUPER_ADMIN' : 'ROLE_EMPLOYEE',
      'auth_employee_id': employeeId,
      'app_theme_mode': 'dark',
      'font_size_multiplier': 1.0,
    });
    await AuthStorage.init();
    await ThemeManager.instance.initialize();
  }

  static Widget wrapWidget(
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: const EdgeInsets.only(top: 24, bottom: 24),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routes: routes ?? {},
        home: Material(child: child),
      ),
    );
  }
}
