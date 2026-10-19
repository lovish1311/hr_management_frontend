import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hr_management/app/app.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // Real backend connection active via: adb reverse tcp:8080 tcp:8080
  // NO MockHttpOverrides is installed so every HTTP call hits Spring Boot directly!

  tearDown(() async {
    await AuthStorage.clear();
  });

  testWidgets('Live Visual Test: Real Backend Leave Application Workflow',
      (WidgetTester tester) async {
    debugPrint('===============================================================');
    debugPrint('>>> [REAL BACKEND TEST] Starting on Android Emulator');
    debugPrint('>>> Reverse TCP: 127.0.0.1:8080 -> Spring Boot Host Machine');
    debugPrint('===============================================================');

    // 1. Initialize core storage & clean session
    await AuthStorage.init();
    await AuthStorage.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_production_login_mode', false);
    await ThemeManager.instance.initialize();

    // 2. Launch the Application on the device/emulator
    await tester.pumpWidget(
      const ProviderScope(
        child: HRManagementApp(),
      ),
    );

    // Allow splash screen animations to play and route to Login
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugPrint('>>> [STEP 1] Login Screen rendered.');
    expect(find.byKey(const Key('login_submit_btn')), findsOneWidget,
        reason: 'Login submit button must be visible on the login screen.');

    // Ensure Developer Demo Mode is active: if Production Mode switch is ON, toggle it OFF to Dev Mode
    final prodSwitchFinder = find.byKey(const Key('production_mode_switch'));
    if (prodSwitchFinder.evaluate().isNotEmpty) {
      final prodSwitch = tester.widget<Switch>(prodSwitchFinder.first);
      if (prodSwitch.value == true) {
        debugPrint('>>> [SAFETY] Production mode switch was ON. Toggling to Developer Demo Mode...');
        await tester.tap(prodSwitchFinder);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // 3. Locate and tap the "Lovish (Emp)" Demo Preset chip
    final employeePresetBtn = find.byKey(const Key('preset_employee_btn'));
    expect(employeePresetBtn, findsOneWidget,
        reason: 'Lovish (Emp) preset chip must exist on login screen in Dev mode.');

    debugPrint('>>> [STEP 2] Tapping "Lovish (Emp)" demo preset chip...');
    await tester.tap(employeePresetBtn);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // Verify fields populated
    final emailField = find.byKey(const Key('login_email_input'));
    expect(emailField, findsOneWidget);

    // 4. Tap "Sign In"
    debugPrint('>>> [STEP 3] Scrolling to and tapping "Sign In" button...');
    final signInBtn = find.byKey(const Key('login_submit_btn'));
    expect(signInBtn, findsOneWidget);

    // Ensure keyboard is closed and Sign In button is fully visible in scroll view
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(signInBtn);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 500));

    await tester.tap(signInBtn);

    // Wait for real network auth roundtrip and navigation transition
    debugPrint('>>> [STEP 3b] Waiting for network auth and transition to home screen...');
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    debugPrint('>>> [STEP 4] Auth state: authenticated=${AuthStorage.isAuthenticated}, role=${AuthStorage.userRole}');

    // 5. Navigate to Leaves via Bottom Navigation Bar (or direct route if needed)
    final leavesBottomNav = find.text('Leaves');
    if (leavesBottomNav.evaluate().isEmpty) {
      debugPrint('>>> [DIAGNOSTIC] "Leaves" text not immediately found in tree. Dumping found Text widgets...');
      for (final element in find.byType(Text).evaluate()) {
        final widget = element.widget as Text;
        if (widget.data != null && widget.data!.isNotEmpty) {
          debugPrint('   Found Text: "${widget.data}"');
        }
      }
    }
    expect(leavesBottomNav, findsAtLeastNWidgets(1),
        reason: 'Bottom navigation must display "Leaves" tab after successful login.');

    debugPrint('>>> [STEP 5] Tapping "Leaves" in bottom navigation bar...');
    await tester.tap(leavesBottomNav.first);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 6. Find and tap the "Apply Leave" Floating Action Button
    debugPrint('>>> [STEP 6] Tapping Floating Action Button ("Apply Leave")...');
    final fab = find.byKey(const Key('leaves_fab_apply'));
    expect(fab, findsOneWidget,
        reason: 'Leaves screen must render the FAB for applying leave.');
    await tester.tap(fab);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // 7. Select "Apply Leave" from the bottom sheet
    debugPrint('>>> [STEP 7] Selecting "Apply Leave" from options sheet...');
    final applyOptionTile = find.byKey(const Key('apply_leave_option_tile'));
    expect(applyOptionTile, findsOneWidget,
        reason: '"Apply Leave" option must exist in the bottom sheet.');
    await tester.tap(applyOptionTile);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    // 8. Select Leave Type (Casual Leave or Sick Leave)
    debugPrint('>>> [STEP 8] Selecting "Casual Leave" card from leave types grid...');
    final casualLeaveTile = find.byKey(const Key('leave_type_Casual Leave'));
    final targetLeaveTile = casualLeaveTile.evaluate().isNotEmpty ? casualLeaveTile : find.text('Casual Leave').first;
    expect(targetLeaveTile, findsOneWidget,
        reason: '"Casual Leave" tile must exist in leave type selection.');

    await tester.ensureVisible(targetLeaveTile);
    await tester.pumpAndSettle();
    await tester.tap(targetLeaveTile, warnIfMissed: false);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // 9. Enter Reason into the form with ensureVisible (safe for small screens)
    debugPrint('>>> [STEP 9] Scrolling to Reason input and typing reason...');
    final reasonField = find.byKey(const Key('leave_reason_input'));
    expect(reasonField, findsOneWidget,
        reason: 'Reason input must be present on Step 2 leave form.');

    await tester.ensureVisible(reasonField);
    await tester.pumpAndSettle();
    await tester.enterText(
        reasonField, 'Real-life test: Medical appointment and rest');
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // Unfocus keyboard so it doesn't obscure the Submit button
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // 10. Scroll to and tap "Apply" button to submit request to backend
    debugPrint('>>> [STEP 10] Scrolling to "Apply" button and submitting to backend...');
    final submitBtn = find.byKey(const Key('apply_leave_submit_btn'));
    expect(submitBtn, findsOneWidget,
        reason: 'Apply submit button must exist at bottom of form.');

    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);

    // Wait for backend processing (pessimistic lock, quota calculation, commit)
    debugPrint('>>> [STEP 11] Waiting for Spring Boot backend response...');
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 11. Inspect SnackBar result from the real backend
    final snackBarFinder = find.byType(SnackBar);
    if (snackBarFinder.evaluate().isNotEmpty) {
      final snackBarWidget = tester.widget<SnackBar>(snackBarFinder.first);
      final contentText = find.descendant(
        of: snackBarFinder.first,
        matching: find.byType(Text),
      );
      if (contentText.evaluate().isNotEmpty) {
        final textWidget = tester.widget<Text>(contentText.first);
        final isSuccess = snackBarWidget.backgroundColor == const Color(0xFF10B981);
        debugPrint('---------------------------------------------------------------');
        debugPrint('>>> BACKEND RESPONSE FEEDBACK: "${textWidget.data}"');
        debugPrint('>>> STATUS: ${isSuccess ? "SUCCESS (HTTP 200/201)" : "BUSINESS RULE NOTIFICATION (HTTP 4xx)"}');
        debugPrint('---------------------------------------------------------------');
      }
    }

    // Allow user to visibly view the updated leaves page on the emulator
    debugPrint('>>> [COMPLETE] Live visual test finished. View emulator screen.');
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
