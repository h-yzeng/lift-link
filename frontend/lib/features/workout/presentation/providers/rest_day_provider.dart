import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/workout/domain/services/rest_day_suggestion_service.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

part 'rest_day_provider.g.dart';

/// Provider for the rest day suggestion service.
@Riverpod(keepAlive: true)
RestDaySuggestionService restDaySuggestionService(
    RestDaySuggestionServiceRef ref) {
  return RestDaySuggestionService();
}

/// Provider that computes rest day suggestions based on recent workout history.
///
/// This provider automatically updates when workout history changes,
/// providing real-time rest day recommendations.
///
/// Example usage:
/// ```dart
/// final suggestion = ref.watch(restDaySuggestionProvider);
/// suggestion.when(
///   data: (suggestion) {
///     if (suggestion.shouldRest) {
///       // Show rest day recommendation
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@riverpod
Future<RestDaySuggestion> restDaySuggestion(RestDaySuggestionRef ref) async {
  // Get workout history for the last 14 days
  final now = DateTime.now();
  final twoWeeksAgo = now.subtract(const Duration(days: 14));

  final historyResult = await ref.watch(
    workoutHistoryProvider(
      limit: 50,
      startDate: twoWeeksAgo,
      endDate: now,
    ).future,
  );

  return historyResult.fold(
    (_) => const RestDaySuggestion(
      shouldRest: false,
      confidenceLevel: ConfidenceLevel.low,
      reason: 'Unable to load workout history',
      daysUntilRecommendedRest: 1,
    ),
    (workouts) {
      final service = ref.read(restDaySuggestionServiceProvider);
      return service.suggestRestDay(workouts);
    },
  );
}
