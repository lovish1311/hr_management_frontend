import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/attendance/presentation/pages/attendance_calendar_page.dart';
import 'package:hr_management/features/auth/presentation/pages/login_page.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_directory_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_profile_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_management_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/hr_leave_settings_page.dart';
import 'package:hr_management/features/home/presentation/pages/employee_home_page.dart';
import 'package:hr_management/features/payroll/presentation/pages/payslip_page.dart';
import 'package:hr_management/features/people/presentation/pages/people_page.dart';
import 'package:hr_management/features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/login': (context) => const LoginPage(),
      '/': (context) => AuthStorage.isHr ? const DashboardPage() : const EmployeeHomePage(),
      '/employees': (context) => const EmployeeDirectoryPage(),
      '/employee_profile': (context) => const EmployeeProfilePage(),
      '/attendance': (context) => const AttendanceCalendarPage(),
      '/leaves': (context) => const LeaveManagementPage(),
      '/hr_leave_settings': (context) => const HrLeaveSettingsPage(),
      '/payslip': (context) => const PayslipPage(),
      '/people': (context) => const PeoplePage(),
        '/settings': (context) => const SettingsPage(),
    };
  }
}


