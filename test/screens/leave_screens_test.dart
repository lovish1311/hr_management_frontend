import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/leaves/presentation/pages/hr_leave_settings_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_management_page.dart';
import 'package:hr_management/features/leaves/presentation/pages/leave_policy_handbook_page.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Leave Screens Responsive & Overflow Tests', () {
    testWidgets('LeaveManagementPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'LeaveManagementPage',
        route: '/leaves',
        builder: () => const LeaveManagementPage(),
      );
    });

    testWidgets('HrLeaveSettingsPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'HrLeaveSettingsPage',
        route: '/hr_leave_settings',
        builder: () => const HrLeaveSettingsPage(),
      );
    });

    testWidgets('LeavePolicyHandbookPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'LeavePolicyHandbookPage',
        route: '/leave_policy',
        builder: () => const LeavePolicyHandbookPage(),
      );
    });
  });
}
