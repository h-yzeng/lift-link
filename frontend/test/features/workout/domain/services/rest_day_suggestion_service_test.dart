import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/services/rest_day_suggestion_service.dart';

void main() {
  group('RestDaySuggestionService', () {
    late RestDaySuggestionService service;

    setUp(() {
      service = RestDaySuggestionService();
    });

    test('suggests rest after 6 consecutive days', () {
      // Arrange
      final workouts = _createConsecutiveWorkouts(6);

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isTrue);
      expect(suggestion.confidenceLevel, ConfidenceLevel.high);
      expect(suggestion.reason, contains('6 consecutive days'));
    });

    test('suggests rest with high volume and 4 consecutive days', () {
      // Arrange
      final workouts = _createConsecutiveWorkouts(4, highVolume: true);

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isTrue);
      expect(suggestion.confidenceLevel, ConfidenceLevel.high);
    });

    test('suggests rest with long workouts and 3 consecutive days', () {
      // Arrange
      final workouts = _createConsecutiveWorkouts(3, longDuration: true);

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isTrue);
      expect(suggestion.confidenceLevel, ConfidenceLevel.medium);
    });

    test('does not suggest rest with good recovery', () {
      // Arrange
      final workouts = [
        _createWorkout(DateTime.now().subtract(const Duration(days: 5))),
        _createWorkout(DateTime.now().subtract(const Duration(days: 6))),
      ];

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isFalse);
      expect(suggestion.reason, contains('well-rested'));
    });

    test('handles empty workout list', () {
      // Act
      final suggestion = service.suggestRestDay([]);

      // Assert
      expect(suggestion.shouldRest, isFalse);
      expect(suggestion.confidenceLevel, ConfidenceLevel.high);
      expect(suggestion.daysUntilRecommendedRest, 0);
    });

    test('suggests rest day after tomorrow for 2 consecutive days', () {
      // Arrange
      final workouts = _createConsecutiveWorkouts(2);

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isFalse);
      expect(suggestion.daysUntilRecommendedRest, 1);
      expect(suggestion.reason, contains('2 consecutive days'));
    });

    test('calculates consecutive days correctly with gaps', () {
      // Arrange
      final workouts = [
        _createWorkout(DateTime.now()),
        _createWorkout(DateTime.now().subtract(const Duration(days: 1))),
        // Gap here
        _createWorkout(DateTime.now().subtract(const Duration(days: 5))),
        _createWorkout(DateTime.now().subtract(const Duration(days: 6))),
      ];

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert - should only count the 2 recent consecutive days
      expect(suggestion.shouldRest, isFalse);
      expect(suggestion.daysUntilRecommendedRest, greaterThan(0));
    });

    test('provides balanced schedule message for optimal training', () {
      // Arrange
      final workouts = [
        _createWorkout(DateTime.now().subtract(const Duration(days: 1))),
        _createWorkout(DateTime.now().subtract(const Duration(days: 3))),
        _createWorkout(DateTime.now().subtract(const Duration(days: 5))),
      ];

      // Act
      final suggestion = service.suggestRestDay(workouts);

      // Assert
      expect(suggestion.shouldRest, isFalse);
      expect(suggestion.reason, contains('balanced'));
    });
  });
}

/// Helper function to create consecutive workouts.
List<WorkoutSession> _createConsecutiveWorkouts(
  int count, {
  bool highVolume = false,
  bool longDuration = false,
}) {
  final workouts = <WorkoutSession>[];

  for (var i = 0; i < count; i++) {
    final date = DateTime.now().subtract(Duration(days: i));
    final workout = _createWorkout(
      date,
      exerciseCount: highVolume ? 8 : 4,
      duration: longDuration ? 120 : 60,
    );
    workouts.add(workout);
  }

  return workouts;
}

/// Helper function to create a single workout.
WorkoutSession _createWorkout(
  DateTime date, {
  int exerciseCount = 4,
  int duration = 60,
}) {
  final exercises = List.generate(
    exerciseCount,
    (index) => ExercisePerformance(
      id: 'exercise-$index',
      workoutSessionId: 'workout-1',
      exerciseId: 'ex-$index',
      exerciseName: 'Exercise $index',
      sets: [
        WorkoutSet(
          id: 'set-$index-1',
          exercisePerformanceId: 'exercise-$index',
          setNumber: 1,
          weightKg: 100,
          reps: 10,
          createdAt: date,
          updatedAt: date,
        ),
        WorkoutSet(
          id: 'set-$index-2',
          exercisePerformanceId: 'exercise-$index',
          setNumber: 2,
          weightKg: 100,
          reps: 10,
          createdAt: date,
          updatedAt: date,
        ),
      ],
      orderIndex: index,
      createdAt: date,
      updatedAt: date,
    ),
  );

  return WorkoutSession(
    id: 'workout-1',
    userId: 'user-1',
    title: 'Test Workout',
    startedAt: date,
    completedAt: date.add(Duration(minutes: duration)),
    durationMinutes: duration,
    exercises: exercises,
    createdAt: date,
    updatedAt: date,
  );
}
