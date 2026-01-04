import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/social/domain/services/workout_sharing_service.dart';

void main() {
  group('WorkoutSharingService', () {
    late WorkoutSharingService service;

    setUp(() {
      service = WorkoutSharingService();
    });

    test('generates workout summary with all details', () {
      // Arrange
      final workout = _createSampleWorkout();

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('Test Workout'));
      expect(summary, contains('Duration: 60 minutes'));
      expect(summary, contains('Exercises: 2'));
      expect(summary, contains('Bench Press'));
      expect(summary, contains('Squat'));
      expect(summary, contains('lbs'));
      expect(summary, contains('LiftLink'));
    });

    test('generates summary with metric units', () {
      // Arrange
      final workout = _createSampleWorkout();

      // Act
      final summary = service.generateWorkoutSummary(workout, false);

      // Assert
      expect(summary, contains('kg'));
      expect(summary, isNot(contains('lbs')));
    });

    test('includes exercise notes in summary', () {
      // Arrange
      final workout = _createSampleWorkout(
        exerciseNotes: 'Felt strong today!',
      );

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('Felt strong today!'));
    });

    test('includes workout notes in summary', () {
      // Arrange
      final workout = _createSampleWorkout(
        workoutNotes: 'Great session overall',
      );

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('Great session overall'));
    });

    test('calculates total volume correctly', () {
      // Arrange
      final workout = _createSampleWorkout();

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      // 2 exercises × 3 sets × 100 lbs × 10 reps = 6000 lbs
      expect(summary, contains('Total Volume: 6000'));
    });

    test('generates achievement post with streak', () {
      // Arrange
      final workout = _createSampleWorkout();

      // Act
      final post = service.generateAchievementPost(
        workout,
        currentStreak: 7,
        useImperialUnits: true,
      );

      // Assert
      expect(post, contains('Workout Complete!'));
      expect(post, contains('7 day streak'));
      expect(post, contains('🔥'));
    });

    test('generates achievement post with personal records', () {
      // Arrange
      final workout = _createSampleWorkout();
      final prs = ['Bench Press: 225 lbs', 'Squat: 315 lbs'];

      // Act
      final post = service.generateAchievementPost(
        workout,
        personalRecords: prs,
        useImperialUnits: true,
      );

      // Assert
      expect(post, contains('New Personal Records'));
      expect(post, contains('Bench Press: 225 lbs'));
      expect(post, contains('Squat: 315 lbs'));
      expect(post, contains('🏆'));
    });

    test('generates quick stats with emojis', () {
      // Arrange
      final workout = _createSampleWorkout();

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('💪'));
      expect(summary, contains('📊'));
      expect(summary, contains('⏱️'));
    });

    test('generates progress comparison', () {
      // Arrange
      final currentWorkout = _createSampleWorkout(weight: 120);
      final previousWorkout = _createSampleWorkout(weight: 100);

      // Act
      final comparison = service.generateProgressComparison(
        currentWorkout,
        previousWorkout,
        true,
      );

      // Assert
      expect(comparison, contains('Progress Update!'));
      expect(comparison, contains('Today vs Last Time'));
      expect(comparison, contains('Volume:'));
      expect(comparison, contains('Duration:'));
      // Current volume (2 exercises × 3 sets × 120 lbs × 10 reps) = 7200
      // Previous volume (2 exercises × 3 sets × 100 lbs × 10 reps) = 6000
      // Difference = 1200 lbs
      expect(comparison, contains('7200'));
      expect(comparison, contains('6000'));
    });

    test('shows positive volume change in comparison', () {
      // Arrange
      final currentWorkout = _createSampleWorkout(weight: 150);
      final previousWorkout = _createSampleWorkout(weight: 100);

      // Act
      final comparison = service.generateProgressComparison(
        currentWorkout,
        previousWorkout,
        true,
      );

      // Assert
      expect(comparison, contains('+'));
      expect(comparison, contains('Keep up the great work!'));
    });

    test('shows encouraging message for lower volume', () {
      // Arrange
      final currentWorkout = _createSampleWorkout(weight: 80);
      final previousWorkout = _createSampleWorkout(weight: 100);

      // Act
      final comparison = service.generateProgressComparison(
        currentWorkout,
        previousWorkout,
        true,
      );

      // Assert
      expect(comparison, contains('Every workout counts!'));
    });

    test('handles zero weight sets', () {
      // Arrange
      final workout = _createSampleWorkout(weight: 0);

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('Total Volume: 0'));
    });

    test('formats date correctly', () {
      // Arrange
      final workout = WorkoutSession(
        id: 'w1',
        userId: 'u1',
        title: 'Test',
        startedAt: DateTime(2025, 1, 15, 10, 30),
        completedAt: DateTime(2025, 1, 15, 11, 30),
        durationMinutes: 60,
        exercises: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final summary = service.generateWorkoutSummary(workout, true);

      // Assert
      expect(summary, contains('2025'));
      expect(summary, contains('January'));
    });
  });
}

/// Helper to create a sample workout for testing.
WorkoutSession _createSampleWorkout({
  double weight = 100,
  String? exerciseNotes,
  String? workoutNotes,
}) {
  final now = DateTime.now();

  final exercises = [
    ExercisePerformance(
      id: 'ex1',
      workoutSessionId: 'w1',
      exerciseId: 'e1',
      exerciseName: 'Bench Press',
      sets: List.generate(
        3,
        (i) => WorkoutSet(
          id: 'set1-$i',
          exercisePerformanceId: 'ex1',
          setNumber: i + 1,
          weightKg: weight,
          reps: 10,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      orderIndex: 0,
      notes: exerciseNotes,
      createdAt: now,
      updatedAt: now,
    ),
    ExercisePerformance(
      id: 'ex2',
      workoutSessionId: 'w1',
      exerciseId: 'e2',
      exerciseName: 'Squat',
      sets: List.generate(
        3,
        (i) => WorkoutSet(
          id: 'set2-$i',
          exercisePerformanceId: 'ex2',
          setNumber: i + 1,
          weightKg: weight,
          reps: 10,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      orderIndex: 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  return WorkoutSession(
    id: 'w1',
    userId: 'u1',
    title: 'Test Workout',
    startedAt: now,
    completedAt: now.add(const Duration(minutes: 60)),
    durationMinutes: 60,
    exercises: exercises,
    notes: workoutNotes,
    createdAt: now,
    updatedAt: now,
  );
}
