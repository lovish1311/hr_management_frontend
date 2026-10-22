import 'package:flutter/material.dart';
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

    testWidgets('SettingsPage selecting theme triggers Apply button from Applied to Apply Changes', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          const SettingsPage(),
          size: const Size(1280, 1000),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, when no settings are changed, the button is "Applied"
      expect(find.text('Applied'), findsWidgets);

      // Scroll and tap on a theme card (e.g. Sunset / Midnight / Arctic)
      final sunsetTheme = find.text('Sunset');
      expect(sunsetTheme, findsOneWidget);
      await tester.ensureVisible(sunsetTheme);
      await tester.tap(sunsetTheme);
      await tester.pumpAndSettle();

      // Now changes are detected dynamically: button triggers to "Apply Changes" (or "Apply")
      expect(find.textContaining('Apply'), findsWidgets);
      expect(find.text('Applied'), findsNothing);

      // Tap Apply Changes button
      final applyBtn = find.textContaining('Apply');
      await tester.ensureVisible(applyBtn.first);
      await tester.tap(applyBtn.first);
      await tester.pumpAndSettle();

      // Once applied, button reverts to "Applied"
      expect(find.text('Applied'), findsWidgets);
    });
  });
}
