import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/payroll/presentation/pages/payslip_page.dart';
import 'package:hr_management/features/settings/presentation/pages/settings_page.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Payroll & Settings Screens Responsive & Overflow Tests', () {
    testWidgets('PayslipPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'PayslipPage',
        route: '/payslip',
        builder: () => const PayslipPage(),
      );
    });

    testWidgets('SettingsPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'SettingsPage',
        route: '/settings',
        builder: () => const SettingsPage(),
      );
    });
  });
}
