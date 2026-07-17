import 'package:flutter/material.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';

// Package: hr_management

import 'package:hr_management/features/employees/presentation/pages/employee_directory_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_profile_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const DashboardPage(),
      '/employees': (context) => const EmployeeDirectoryPage(),
      '/employee_profile': (context) => const EmployeeProfilePage(),
    };
  }
}
