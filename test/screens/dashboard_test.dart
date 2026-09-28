import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hr_management/features/home/presentation/pages/employee_home_page.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Dashboard Screens Responsive & Overflow Tests', () {
    testWidgets('DashboardPage (Admin) renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'DashboardPage',
        route: '/',
        builder: () => const DashboardPage(),
      );
    });

    testWidgets('EmployeeHomePage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EmployeeHomePage',
        route: '/',
        builder: () => const EmployeeHomePage(),
      );
    });
  });
}
