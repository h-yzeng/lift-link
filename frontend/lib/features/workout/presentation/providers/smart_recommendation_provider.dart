import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/workout/domain/services/smart_workout_recommendation_service.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

part 'smart_recommendation_provider.g.dart';

/// Provider for smart workout recommendation service.
@Riverpod(keepAlive: true)
SmartWorkoutRecommendationService smartWorkoutRecommendationService(
  Ref ref,
) {
  return SmartWorkoutRecommendationService();
}

/// Provider that generates workout recommendations based on recent history.
///
/// Analyzes the last 30 days of workouts to provide intelligent suggestions
/// for exercises, timing, and training balance.
///
/// Example:
/// ```dart
/// final recommendations = ref.watch(workoutRecommendationsProvider);
/// recommendations.when(
///   data: (recs) => Text(recs.reasoning),
///   loading: () => CircularProgressIndicator(),
///   error: (err, _) => Text('Error: $err'),
/// );
/// ```
@riverpod
Future<WorkoutRecommendations> workoutRecommendations(
  Ref ref,
) async {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // workoutHistoryProvider returns Future<List<WorkoutSession>> directly
  final workouts = await ref.watch(
    workoutHistoryProvider(
      limit: 50,
      startDate: thirtyDaysAgo,
      endDate: now,
    ).future,
  );

  final service = ref.read(smartWorkoutRecommendationServiceProvider);
  return service.generateRecommendations(workouts);
}

/// Provider for exercise suggestions.
///
/// Returns a list of suggested exercises based on training patterns.
@riverpod
Future<List<ExerciseSuggestion>> exerciseSuggestions(
  Ref ref, {
  int count = 5,
}) async {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // workoutHistoryProvider returns Future<List<WorkoutSession>> directly
  final workouts = await ref.watch(
    workoutHistoryProvider(
      limit: 50,
      startDate: thirtyDaysAgo,
      endDate: now,
    ).future,
  );

  final service = ref.read(smartWorkoutRecommendationServiceProvider);
  return service.suggestNextExercises(workouts, count);
}

/// Provider for workout timing recommendations.
@riverpod
Future<TimeRecommendation> workoutTimingRecommendation(
  Ref ref,
) async {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // workoutHistoryProvider returns Future<List<WorkoutSession>> directly
  final workouts = await ref.watch(
    workoutHistoryProvider(
      limit: 50,
      startDate: thirtyDaysAgo,
      endDate: now,
    ).future,
  );

  final service = ref.read(smartWorkoutRecommendationServiceProvider);
  return service.suggestWorkoutTiming(workouts);
}
