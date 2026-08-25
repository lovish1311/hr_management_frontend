import 'package:flutter/material.dart';
import 'package:hr_management/features/auth/presentation/pages/login_page.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_directory_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_profile_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_management_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/hr_leave_settings_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/login': (context) => const LoginPage(),
      '/': (context) => const DashboardPage(),
      '/employees': (context) => const EmployeeDirectoryPage(),
      '/employee_profile': (context) => const EmployeeProfilePage(),
      '/leaves': (context) => const LeaveManagementPage(),
      '/hr_leave_settings': (context) => const HrLeaveSettingsPage(),
    };
  }
}
