import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/features/attendance/presentation/pages/attendance_calendar_page.dart';
import 'package:hr_management/features/auth/presentation/pages/login_page.dart';
import 'package:hr_management/features/auth/presentation/pages/splash_screen.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_directory_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_profile_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:hr_management/features/holidays/presentation/pages/holiday_calendar_page.dart';
import 'package:hr_management/features/holidays/presentation/pages/holiday_management_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_management_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/hr_leave_settings_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_policy_handbook_page.dart';
import 'package:hr_management/features/home/presentation/pages/employee_home_page.dart';
import 'package:hr_management/features/payroll/presentation/pages/payslip_page.dart';
import 'package:hr_management/features/people/presentation/pages/people_page.dart';
import 'package:hr_management/features/settings/presentation/pages/settings_page.dart';
import 'package:hr_management/features/games/presentation/pages/game_directory_page.dart';
import 'package:hr_management/features/tambola/presentation/pages/tambola_lobby_page.dart';
import 'package:hr_management/features/tambola/presentation/pages/tambola_game_room_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/splash': (context) => const SplashScreen(),
      '/login': (context) => const LoginPage(),
      '/': (context) => AuthStorage.isSuperAdmin ? const DashboardPage() : const EmployeeHomePage(),
      '/employees': (context) => const EmployeeDirectoryPage(),
      '/employee_profile': (context) => const EmployeeProfilePage(),
      '/employee_create': (context) => const EmployeeFormPage(),
      '/employee_edit': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return EmployeeFormPage(
          initialEmployee: args is Employee ? args : null,
        );
      },
      '/attendance': (context) => const AttendanceCalendarPage(),
      '/leaves': (context) => const LeaveManagementPage(),
      '/leave-management': (context) => const LeaveManagementPage(),
      '/holidays': (context) => const HolidayCalendarPage(),
      '/holiday_management': (context) => const HolidayManagementPage(),
      '/hr_leave_settings': (context) => const HrLeaveSettingsPage(),
      '/leave_policy': (context) => const LeavePolicyHandbookPage(),
      '/payslip': (context) => const PayslipPage(),
      '/people': (context) => const PeoplePage(),
      '/settings': (context) => const SettingsPage(),
      '/games': (context) => const GameDirectoryPage(),
      '/tambola': (context) => const TambolaLobbyPage(),
      '/tambola_game': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return TambolaGameRoomPage(
          roomCode: args is String ? args : (args != null ? args.toString() : ''),
        );
      },
      '/profile': (context) => const EmployeeProfilePage(),
      '/leave': (context) => const LeaveManagementPage(),
      '/payroll': (context) => const PayslipPage(),
      '/dashboard': (context) => const DashboardPage(),
    };
  }
}
