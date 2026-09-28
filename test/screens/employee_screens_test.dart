import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_directory_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:hr_management/features/employees/presentation/pages/employee_profile_page.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Employee Screens Responsive & Overflow Tests', () {
    testWidgets('EmployeeDirectoryPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EmployeeDirectoryPage',
        route: '/employees',
        builder: () => const EmployeeDirectoryPage(),
      );
    });

    testWidgets('EmployeeFormPage (Create) renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EmployeeFormPage',
        route: '/employee_create',
        builder: () => const EmployeeFormPage(),
      );
    });

    testWidgets('EmployeeFormPage (Edit with existing employee) renders with 0 overflows', (tester) async {
      final sampleEmployee = Employee(
        id: '1',
        name: 'Ankesh Verma',
        role: 'Director',
        department: 'Engineering',
        email: 'ankesh@company.com',
        phone: '+91 98765 43210',
        joiningDate: '2022-01-15',
        status: 'Active',
        isProbation: true,
        probationDurationMonths: 3,
        isNoticePeriod: true,
        noticeDurationDays: 30,
        managerName: 'Board of Directors',
        dateOfBirth: '1990-01-01',
        emergencyContactName: 'Family Contact',
        emergencyContactPhone: '+91 98765 00000',
      );

      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EmployeeFormPage (Edit)',
        route: '/employee_edit',
        builder: () => EmployeeFormPage(initialEmployee: sampleEmployee),
      );
    });

    testWidgets('EmployeeProfilePage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EmployeeProfilePage',
        route: '/employee_profile',
        builder: () => const EmployeeProfilePage(),
      );
    });
  });
}
