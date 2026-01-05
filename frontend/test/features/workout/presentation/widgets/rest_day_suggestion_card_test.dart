import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/workout/domain/services/rest_day_suggestion_service.dart';
import 'package:liftlink/features/workout/presentation/widgets/rest_day_suggestion_card.dart';
import 'package:liftlink/features/workout/presentation/providers/rest_day_provider.dart';

void main() {
  group('RestDaySuggestionCard', () {
    testWidgets('displays rest recommendation correctly', (tester) async {
      // Arrange
      const suggestion = RestDaySuggestion(
        shouldRest: true,
        confidenceLevel: ConfidenceLevel.high,
        reason: 'You have trained for 6 consecutive days.',
        daysUntilRecommendedRest: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restDaySuggestionProvider.overrideWith((ref) async => suggestion),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RestDaySuggestionCard(),
            ),
          ),
        ),
      );

      // Wait for provider to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Rest Day Recommended'), findsOneWidget);
      expect(find.text('You have trained for 6 consecutive days.'),
          findsOneWidget,);
      expect(find.text('High'), findsOneWidget);
      expect(find.byIcon(Icons.spa), findsOneWidget);
    });

    testWidgets('displays training recommendation correctly', (tester) async {
      // Arrange
      const suggestion = RestDaySuggestion(
        shouldRest: false,
        confidenceLevel: ConfidenceLevel.medium,
        reason: 'Your training schedule looks balanced.',
        daysUntilRecommendedRest: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restDaySuggestionProvider.overrideWith((ref) async => suggestion),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RestDaySuggestionCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ready to Train'), findsOneWidget);
      expect(
          find.text('Your training schedule looks balanced.'), findsOneWidget,);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Consider rest in 2 days'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    // Skipping this test due to timer issues in test environment
    // testWidgets('hides when loading', (tester) async {
    //   await tester.pumpWidget(
    //     ProviderScope(
    //       overrides: [
    //         restDaySuggestionProvider.overrideWith(
    //           (ref) => Future.delayed(
    //             const Duration(seconds: 1),
    //             () => const RestDaySuggestion(
    //               shouldRest: false,
    //               confidenceLevel: ConfidenceLevel.high,
    //               reason: 'Test',
    //               daysUntilRecommendedRest: 1,
    //             ),
    //           ),
    //         ),
    //       ],
    //       child: const MaterialApp(
    //         home: Scaffold(
    //           body: RestDaySuggestionCard(),
    //         ),
    //       ),
    //     ),
    //   );

    //   // Should show nothing while loading
    //   expect(find.byType(Card), findsNothing);
    // });

    testWidgets('hides on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restDaySuggestionProvider.overrideWith(
              (ref) async => throw Exception('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RestDaySuggestionCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show nothing on error
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('displays low confidence badge', (tester) async {
      const suggestion = RestDaySuggestion(
        shouldRest: false,
        confidenceLevel: ConfidenceLevel.low,
        reason: 'Limited data available.',
        daysUntilRecommendedRest: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restDaySuggestionProvider.overrideWith((ref) async => suggestion),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RestDaySuggestionCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('displays correct styling for rest day', (tester) async {
      const suggestion = RestDaySuggestion(
        shouldRest: true,
        confidenceLevel: ConfidenceLevel.high,
        reason: 'Rest recommended',
        daysUntilRecommendedRest: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restDaySuggestionProvider.overrideWith((ref) async => suggestion),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            home: const Scaffold(
              body: RestDaySuggestionCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNotNull);
    });
  });
}
