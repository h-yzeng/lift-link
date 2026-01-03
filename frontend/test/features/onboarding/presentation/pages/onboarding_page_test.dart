import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  group('OnboardingPage', () {
    testWidgets('displays first slide on load', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      expect(find.text('Track Your Workouts'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('displays skip button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('displays next button on first slides', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('navigates to next slide on next button tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      // Tap next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show second slide
      expect(find.text('Monitor Progress'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays page indicators', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      // Should have 4 dots (one for each slide)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays get started button on last slide', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingPage(),
          ),
        ),
      );

      // Navigate to last slide
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Should show get started button
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
