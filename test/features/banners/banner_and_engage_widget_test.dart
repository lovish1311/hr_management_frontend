import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/widgets/emoji_reaction_bar.dart';
import 'package:hr_management/features/banners/presentation/widgets/news_feed_card.dart';
import 'package:hr_management/features/banners/presentation/widgets/spotlight_card.dart';
import '../../helpers/responsive_tester.dart';
import '../../helpers/test_app_wrapper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestAppWrapper.setup();
  });

  group('NewsFeedCard Responsive and Overflow Tests', () {
    final testNewsBanner = BannerModel.fromJson({
      'id': 1,
      'title': 'Company Innovation Summit 2026 Announced with Keynote Speakers',
      'subtitle': 'Join us for 3 days of cutting-edge technology keynotes, interactive workshops, and gala dinners celebrating our milestone achievements.',
      'bannerType': 'NEWS',
      'category': 'ANNOUNCEMENT',
      'imageUrl': '/api/v1/banners/images/sample_innovation.png',
      'actionButtonText': 'Register Now',
      'actionUrl': 'https://company.example.com/summit',
      'reactionCounts': {'LIKE': 12, 'CELEBRATE': 8, 'HEART': 5},
      'userReactions': ['LIKE'],
      'totalReactions': 25,
      'startDate': DateTime.now().toIso8601String(),
      'expiryDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'displayOrder': 1,
      'isActive': true,
      'version': 1,
      'isCurrentlyActive': true,
      'isExpired': false,
      'isScheduled': false,
    });

    testWidgets('NewsFeedCard renders with zero overflows across all screen sizes', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'NewsFeedCard',
        route: '/engage',
        builder: () => Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NewsFeedCard(
                banner: testNewsBanner,
                onReactionTapped: (_) {},
                onActionTapped: () {},
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('NewsFeedCard displays title, category, and reactions accurately', (tester) async {
      String? tappedReaction;
      bool actionTapped = false;

      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: NewsFeedCard(
                banner: testNewsBanner,
                onReactionTapped: (type) => tappedReaction = type,
                onActionTapped: () => actionTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Company Innovation Summit 2026 Announced with Keynote Speakers'), findsOneWidget);
      expect(find.text('ANNOUNCEMENT'), findsOneWidget);
      expect(find.text('Register Now'), findsOneWidget);

      // Verify tapping reaction
      final thumbsUpFinder = find.text('👍');
      expect(thumbsUpFinder, findsOneWidget);
      await tester.ensureVisible(thumbsUpFinder);
      await tester.tap(thumbsUpFinder);
      expect(tappedReaction, 'LIKE');

      // Verify tapping action button
      await tester.tap(find.text('Register Now'));
      expect(actionTapped, isTrue);
    });
  });

  group('SpotlightCard Responsive and Overflow Tests', () {
    final testBirthdayBanner = BannerModel.fromJson({
      'id': 2,
      'title': 'Happy Birthday, Jessica!',
      'subtitle': 'Wishing our Senior Product Designer a fantastic day and another year filled with inspiring creativity and success! 🎂🎈',
      'bannerType': 'CELEBRATION',
      'celebrationType': 'BIRTHDAY',
      'category': 'GENERAL',
      'targetEmployeeId': 42,
      'targetEmployeeName': 'Jessica Martinez',
      'targetEmployeeDepartment': 'Engineering',
      'reactionCounts': {'PARTY': 15, 'HEART': 9, 'CLAP': 6},
      'userReactions': ['PARTY'],
      'totalReactions': 30,
      'startDate': DateTime.now().toIso8601String(),
      'expiryDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'displayOrder': 2,
      'isActive': true,
      'version': 1,
      'isCurrentlyActive': true,
      'isExpired': false,
      'isScheduled': false,
    });

    testWidgets('SpotlightCard renders with zero overflows across all screen sizes', (tester) async {
      await ResponsiveTester.testScreen(
        tester: tester,
        screenName: 'SpotlightCard',
        route: '/engage',
        builder: () => Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SpotlightCard(
                banner: testBirthdayBanner,
                onReactionTapped: (_) {},
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('SpotlightCard displays recipient name and birthday badge', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: SpotlightCard(
                banner: testBirthdayBanner,
                onReactionTapped: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Jessica Martinez'), findsOneWidget);
      expect(find.text('BIRTHDAY CELEBRATION 🎂'), findsOneWidget);
      expect(find.text('JM'), findsOneWidget); // Initials
      expect(find.text('Happy Birthday, Jessica!'), findsOneWidget);
    });
  });

  group('EmojiReactionBar Widget Tests', () {
    testWidgets('EmojiReactionBar highlights user-reacted items with micro-badges', (tester) async {
      String? clicked;
      await tester.pumpWidget(
        TestAppWrapper.wrapWidget(
          Scaffold(
            body: EmojiReactionBar(
              reactionCounts: const {'LIKE': 5, 'CELEBRATE': 3},
              userReactions: const {'LIKE'},
              onReactionTapped: (k) => clicked = k,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('🎉'));
      expect(clicked, 'CELEBRATE');
    });
  });
}
