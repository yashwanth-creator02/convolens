import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/onboarding/screens/onboarding_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'Tapping Skip navigates directly to history page destination',
    (WidgetTester tester) async {
      bool onFinishCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            db: db,
            onFinish: () => onFinishCalled = true,
            homeBuilder: (context) =>
                const Scaffold(body: Center(child: Text('History Page'))),
          ),
        ),
      );

      // Verify Skip button exists on initial screen
      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);

      // Tap Skip
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(onFinishCalled, isTrue);
      // History Page destination should now be displayed
      expect(find.text('History Page'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'Page 3 does not show Optional tags on permission tiles, and Get Started navigates to history page',
    (WidgetTester tester) async {
      bool onFinishCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            db: db,
            onFinish: () => onFinishCalled = true,
            homeBuilder: (context) =>
                const Scaffold(body: Center(child: Text('History Page'))),
          ),
        ),
      );

      // Page 1 -> Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Page 2 -> Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // On Page 3: Verify the header mentions Optional
      expect(find.text('Additional Tools (Optional)'), findsOneWidget);

      // Verify that no individual permission tile has an "Optional" tag
      expect(find.text('Optional'), findsNothing);

      // Tap "Get Started"
      final getStartedButton = find.text('Get Started');
      expect(getStartedButton, findsOneWidget);
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      expect(onFinishCalled, isTrue);
      // History Page destination should now be displayed
      expect(find.text('History Page'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'Revisit mode: Skip is hidden, Done button pops back',
    (WidgetTester tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          db: db,
                          onFinish: () {},
                          isRevisit: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Onboarding'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Onboarding in revisit mode
      await tester.tap(find.text('Open Onboarding'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      // Skip should NOT be visible in revisit mode
      expect(find.text('Skip'), findsNothing);

      // Advance to page 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Page 3 action button says "Done" in revisit mode
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should have popped back to previous screen
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Open Onboarding'), findsOneWidget);
    },
  );
}
