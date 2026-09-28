import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/holidays/presentation/pages/holiday_calendar_page.dart';
import 'package:hr_management/features/holidays/presentation/pages/holiday_management_page.dart';
import 'package:hr_management/features/holidays/presentation/widgets/add_holiday_dialog.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('Holiday Screens Responsive & Overflow Tests', () {
    testWidgets('HolidayCalendarPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'HolidayCalendarPage',
        route: '/holidays',
        builder: () => const HolidayCalendarPage(),
      );
    });

    testWidgets('HolidayManagementPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'HolidayManagementPage',
        route: '/holiday_management',
        builder: () => const HolidayManagementPage(),
      );
    });

    testWidgets('AddHolidayDialog renders with 0 overflows across viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'AddHolidayDialog',
        route: 'dialog:add_holiday',
        builder: () => const AddHolidayDialog(holidayListId: 1, year: 2026),
      );
    });
  });
}
