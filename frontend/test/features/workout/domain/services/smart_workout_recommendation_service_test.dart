import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/services/smart_workout_recommendation_service.dart';

void main() {
  group('SmartWorkoutRecommendationService', () {
    late SmartWorkoutRecommendationService service;

    setUp(() {
      service = SmartWorkoutRecommendationService();
    });

    test('provides default recommendations for no workout history', () {
      // Act
      final recommendations = service.generateRecommendations([]);

      // Assert
      expect(recommendations.suggestedExercises, isNotEmpty);
      expect(recommendations.optimalRestDays, 1);
      expect(recommendations.suggestedDuration, 60);
      expect(recommendations.volumeAdjustment, VolumeAdjustment.maintain);
      expect(recommendations.reasoning, contains('foundation'));
    });

    test('suggests exercises based on muscle group balance', () {
      // Arrange - workouts with only chest exercises
      final workouts = [
        _createWorkout(['Bench Press', 'Incline Press']),
        _createWorkout(['Bench Press', 'Chest Flyes']),
        _createWorkout(['Bench Press']),
      ];

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert - should suggest non-chest exercises
      final suggstedMuscleGroups =
          recommendations.suggestedExercises.map((e) => e.muscleGroup).toSet();
      expect(suggstedMuscleGroups, isNot(contains('Chest')));
    });

    test('calculates optimal rest days based on frequency', () {
      // Arrange - high frequency training (6 workouts)
      final workouts = List.generate(
        6,
        (i) => _createWorkout(['Exercise $i'], daysAgo: i),
      );

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert
      expect(recommendations.optimalRestDays, 1);
    });

    test('suggests appropriate workout duration based on volume', () {
      // Arrange - high volume workouts (many sets)
      final workouts = [
        _createWorkout(
          ['Ex1', 'Ex2', 'Ex3', 'Ex4', 'Ex5', 'Ex6'],
          setsPerExercise: 5,
        ),
      ];

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert
      expect(recommendations.suggestedDuration, greaterThanOrEqualTo(75));
    });

    test('recommends volume increase for low volume training', () {
      // Arrange - very low volume
      final workouts = [
        _createWorkout(['Exercise 1'], setsPerExercise: 1),
        _createWorkout(['Exercise 2'], setsPerExercise: 1),
      ];

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert
      expect(recommendations.volumeAdjustment, VolumeAdjustment.increase);
    });

    test('recommends volume decrease for very high volume', () {
      // Arrange - extremely high volume
      final workouts = [
        _createWorkout(
          ['Ex1', 'Ex2', 'Ex3', 'Ex4', 'Ex5', 'Ex6', 'Ex7', 'Ex8'],
          setsPerExercise: 5,
          weight: 200,
        ),
      ];

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert
      expect(recommendations.volumeAdjustment, VolumeAdjustment.decrease);
    });

    test('suggests next exercises with priority scoring', () {
      // Arrange
      final workouts = [
        _createWorkout(['Bench Press'], daysAgo: 1),
        _createWorkout(['Squat'], daysAgo: 15), // Long time ago
      ];

      // Act
      final suggestions = service.suggestNextExercises(workouts, 5);

      // Assert
      expect(suggestions, isNotEmpty);
      expect(suggestions.length, lessThanOrEqualTo(5));
      // Squat or leg exercises should have higher priority
      final legExercises =
          suggestions.where((s) => s.muscleGroup == 'Legs').toList();
      expect(legExercises, isNotEmpty);
    });

    test('provides timing recommendations based on history', () {
      // Arrange - morning workouts
      final workouts = [
        _createWorkout(['Exercise 1'], hour: 8),
        _createWorkout(['Exercise 2'], hour: 9),
        _createWorkout(['Exercise 3'], hour: 7),
      ];

      // Act
      final timing = service.suggestWorkoutTiming(workouts);

      // Assert
      expect(timing.recommendedTimeOfDay, TimeOfDay.morning);
      expect(timing.reasoning, isNotEmpty);
    });

    test('categorizes exercises into muscle groups correctly', () {
      // Arrange
      final workouts = [
        _createWorkout([
          'Bench Press',
          'Squat',
          'Barbell Row',
          'Shoulder Press',
          'Bicep Curl',
        ]),
      ];

      // Act
      final recommendations = service.generateRecommendations(workouts);

      // Assert
      final muscleGroups = recommendations.muscleGroupSuggestions;
      expect(muscleGroups, isNotNull);
    });

    test('handles workouts without completion dates', () {
      // Arrange
      final workout = WorkoutSession(
        id: 'w1',
        userId: 'u1',
        title: 'Test',
        startedAt: DateTime.now(),
        completedAt: null,
        exercises: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - should not throw
      expect(
        () => service.generateRecommendations([workout]),
        returnsNormally,
      );
    });
  });
}

/// Helper to create a workout with specified exercises.
WorkoutSession _createWorkout(
  List<String> exerciseNames, {
  int daysAgo = 0,
  int setsPerExercise = 3,
  double weight = 100,
  int hour = 10,
}) {
  final date = DateTime.now().subtract(Duration(days: daysAgo));
  final startTime = DateTime(date.year, date.month, date.day, hour);

  final exercises = exerciseNames.asMap().entries.map((entry) {
    final index = entry.key;
    final name = entry.value;

    final sets = List.generate(
      setsPerExercise,
      (setIndex) => WorkoutSet(
        id: 'set-$index-$setIndex',
        exercisePerformanceId: 'ex-$index',
        setNumber: setIndex + 1,
        weightKg: weight,
        reps: 10,
        createdAt: date,
        updatedAt: date,
      ),
    );

    return ExercisePerformance(
      id: 'ex-$index',
      workoutSessionId: 'w1',
      exerciseId: 'exercise-$index',
      exerciseName: name,
      sets: sets,
      orderIndex: index,
      createdAt: date,
      updatedAt: date,
    );
  }).toList();

  return WorkoutSession(
    id: 'w1',
    userId: 'u1',
    title: 'Workout',
    startedAt: startTime,
    completedAt: startTime.add(const Duration(minutes: 60)),
    durationMinutes: 60,
    exercises: exercises,
    createdAt: date,
    updatedAt: date,
  );
}
