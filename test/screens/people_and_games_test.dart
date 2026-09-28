import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/games/presentation/pages/game_directory_page.dart';
import 'package:hr_management/features/people/presentation/pages/people_page.dart';
import 'package:hr_management/features/tambola/presentation/pages/tambola_lobby_page.dart';
import '../helpers/test_app_wrapper.dart';
import '../helpers/responsive_tester.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup(isSuperAdmin: true);
  });

  group('People & Games Screens Responsive & Overflow Tests', () {
    testWidgets('PeoplePage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'PeoplePage',
        route: '/people',
        builder: () => const PeoplePage(),
      );
    });

    testWidgets('GameDirectoryPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'GameDirectoryPage',
        route: '/games',
        builder: () => const GameDirectoryPage(),
      );
    });

    testWidgets('TambolaLobbyPage renders with 0 overflows across all viewports and scales', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'TambolaLobbyPage',
        route: '/tambola',
        builder: () => const TambolaLobbyPage(),
      );
    });
  });
}
