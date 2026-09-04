import 'package:flutter/material.dart';
import 'package:hr_management/app/router.dart';
import 'package:hr_management/app/theme.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class HRManagementApp extends StatelessWidget {
  const HRManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final manager = ThemeManager.instance;
        return MaterialApp(
          title: 'HR Management Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: manager.activeThemeConfig.themeMode,
          initialRoute: '/login',
          routes: AppRouter.routes,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(manager.fontSizeMultiplier),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );

      },
    );
  }
}

