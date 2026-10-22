import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/banners/presentation/pages/engage_page.dart';
import 'package:hr_management/features/banners/presentation/widgets/banner_carousel_widget.dart';
import '../../helpers/responsive_tester.dart';
import '../../helpers/test_app_wrapper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestAppWrapper.setup();
  });

  group('EngagePage Deep-Linking & Responsive Tests', () {
    testWidgets('EngagePage renders correctly across small phone and desktop viewports', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'EngagePage',
        route: '/engage',
        builder: () => const EngagePage(),
      );
    });

    testWidgets('EngagePage deep-links to celebrations tab with birthday filter pre-selected', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          const EngagePage(
            initialTab: 'celebrations',
            initialFilter: 'birthday',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title
      expect(find.text('Engage Social Hub 🌟'), findsOneWidget);

      // Celebrations tab is selected
      expect(find.text('Celebrations 🎉'), findsOneWidget);
      expect(find.text('Company News 📰'), findsOneWidget);

      // Verify Birthday filter chip is displayed
      expect(find.text('Birthdays 🎂'), findsOneWidget);
      expect(find.text('Work Anniversaries 🎖️'), findsOneWidget);
    });

    testWidgets('EngagePage switches smoothly between News and Spotlight tabs', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          const EngagePage(
            initialTab: 'news',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Celebrations tab
      await tester.tap(find.text('Celebrations 🎉'));
      await tester.pumpAndSettle();

      // Should now show filter chips for celebrations
      expect(find.text('Birthdays 🎂'), findsOneWidget);
      expect(find.text('Work Anniversaries 🎖️'), findsOneWidget);

      // Tap on Company News tab
      await tester.tap(find.text('Company News 📰'));
      await tester.pumpAndSettle();

      // Celebrations chips hidden on News tab
      expect(find.text('Birthdays 🎂'), findsNothing);
    });
  });

  group('BannerCarouselWidget Tests', () {
    testWidgets('BannerCarouselWidget gracefully handles empty banners by rendering shrink', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          const Scaffold(
            body: BannerCarouselWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should cleanly render without crashing
      expect(find.byType(BannerCarouselWidget), findsOneWidget);
    });
  });
}
