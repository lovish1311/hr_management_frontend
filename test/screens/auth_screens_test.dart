import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/auth/presentation/pages/login_page.dart';
import 'package:hr_management/features/auth/presentation/pages/splash_screen.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup();
  });

  group('Auth Screens Responsive & Overflow Tests', () {
    testWidgets('SplashScreen renders with 0 overflows across all viewports and text scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'SplashScreen',
        route: '/splash',
        builder: () => const SplashScreen(),
      );
    });

    testWidgets('LoginPage renders with 0 overflows across all viewports and text scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'LoginPage',
        route: '/login',
        builder: () => const LoginPage(),
      );
    });
  });
}
