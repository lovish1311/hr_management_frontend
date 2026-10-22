import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/core/services/permission_socket_service.dart';
import 'package:hr_management/features/auth/data/auth_api_service.dart';
import 'package:hr_management/features/auth/presentation/pages/login_page.dart';
import '../../helpers/test_app_wrapper.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup();
    AuthApiService.clearStatusCache();
  });

  tearDown(() {
    PermissionSocketService.instance.disconnect();
    AuthApiService.clearStatusCache();
  });

  group('AuthApiService Account Status & Smart Error Handling', () {
    test('getAccountStatus resolves ACTIVE user and populates in-memory cache', () async {
      final status1 = await AuthApiService.getAccountStatus('admin@company.com');
      expect(status1.status, 'ACTIVE');
      expect(status1.isActive, isTrue);
      expect(status1.isActivated, isTrue);

      // Second call must return from cache
      final status2 = await AuthApiService.getAccountStatus('admin@company.com');
      expect(identical(status1, status2), isTrue);
    });

    test('getAccountStatus resolves PENDING_ACTIVATION for new hire', () async {
      final status = await AuthApiService.getAccountStatus('pending.newhire@company.com');
      expect(status.status, 'PENDING_ACTIVATION');
      expect(status.isPendingActivation, isTrue);
      expect(status.isActivated, isFalse);
      expect(status.firstName, 'Aarav');
    });

    test('getAccountStatus resolves DEACTIVATED for terminated employee', () async {
      final status = await AuthApiService.getAccountStatus('deactivated.user@company.com');
      expect(status.status, 'DEACTIVATED');
      expect(status.isDeactivated, isTrue);
      expect(status.isActivated, isTrue);
    });

    test('getAccountStatus resolves NOT_FOUND for unregistered email', () async {
      final status = await AuthApiService.getAccountStatus('unknown@company.com');
      expect(status.status, 'NOT_FOUND');
      expect(status.isNotFound, isTrue);
    });

    test('login succeeds and returns token payload for valid credentials', () async {
      final res = await AuthApiService.login(
        email: 'admin@company.com',
        password: 'admin',
      );
      expect(res['token'], isNotNull);
      expect(res['role'], 'ROLE_SUPER_ADMIN');
    });
  });

  group('LoginPage Smart Account Status UI Tests', () {
    testWidgets('Entering pending activation email reveals smart action badge and dialog opens with email', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter pending email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'pending.hire@company.com');
      // Advance debounce timer (350ms)
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify smart account status badge is displayed
      final activateBtn = find.text('Enter Activation Key & Set Password');
      expect(find.text('NEW HIRE'), findsOneWidget);
      expect(activateBtn, findsOneWidget);

      // Scroll into view if needed and tap
      await tester.ensureVisible(activateBtn);
      await tester.pumpAndSettle();
      await tester.tap(activateBtn);
      await tester.pumpAndSettle();

      // Dialog opens with Activating for pending.hire@company.com
      expect(find.text('Activate Account'), findsOneWidget);
      expect(find.text('Activating for pending.hire@company.com'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Activate Account'), findsNothing);
    });

    testWidgets('Entering deactivated email reveals red warning badge', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'deactivated.emp@company.com');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify deactivation badge
      expect(find.byIcon(Icons.block_rounded), findsWidgets);
      expect(find.text('This account has been deactivated. Please contact HR.'), findsOneWidget);
    });
  });
}
