import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_detail_page.dart';

void main() {
  group('WorkoutDetailPage', () {
    late WorkoutSession mockWorkout;

    setUp(() {
      mockWorkout = WorkoutSession(
        id: 'workout-1',
        userId: 'user-1',
        title: 'Test Workout',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutDetailPage(workout: mockWorkout),
          ),
        ),
      );

      expect(find.byType(WorkoutDetailPage), findsOneWidget);
    });

    testWidgets('displays workout title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutDetailPage(workout: mockWorkout),
          ),
        ),
      );

      expect(find.text('Test Workout'), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkoutDetailPage(workout: mockWorkout),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
