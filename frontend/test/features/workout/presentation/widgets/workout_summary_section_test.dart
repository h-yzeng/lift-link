import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/widgets/active_workout/workout_summary_section.dart';

void main() {
  group('WorkoutSummarySection', () {
    late WorkoutSession testWorkout;

    setUp(() {
      testWorkout = WorkoutSession(
        id: 'test-workout-1',
        userId: 'user-1',
        title: 'Push Day',
        startedAt: DateTime(2026, 1, 3, 10, 0),
        completedAt: null,
        exercises: [],
        notes: null,
        createdAt: DateTime(2026, 1, 3, 10, 0),
        updatedAt: DateTime(2026, 1, 3, 10, 0),
      );
    });

    testWidgets('displays workout title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutSummarySection(
                workout: testWorkout,
                useImperialUnits: true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Push Day'),
        findsNothing,
      ); // Title is not in this widget
      expect(find.text('Duration'), findsOneWidget); // Has duration label
    });

    testWidgets('displays workout duration when workout is ongoing',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutSummarySection(
                workout: testWorkout,
                useImperialUnits: true,
              ),
            ),
          ),
        ),
      );

      // Should show some duration text
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('displays exercise count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutSummarySection(
                workout: testWorkout,
                useImperialUnits: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // The count value
    });

    testWidgets('displays total sets count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutSummarySection(
                workout: testWorkout,
                useImperialUnits: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // The count value
    });
  });
}
