import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/attendance/presentation/pages/attendance_calendar_page.dart';
import 'package:hr_management/features/attendance/presentation/widgets/biometric_import_dialog.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Attendance Screens Responsive & Overflow Tests', () {
    testWidgets('AttendanceCalendarPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'AttendanceCalendarPage',
        route: '/attendance',
        builder: () => const AttendanceCalendarPage(),
      );
    });

    testWidgets('BiometricImportDialog renders with 0 overflows across viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'BiometricImportDialog',
        route: 'dialog:biometric_import',
        builder: () => BiometricImportDialog(onImportSuccess: () {}),
      );
    });
  });
}
