import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

/// Service for suggesting rest days based on workout history and patterns.
///
/// This service analyzes workout frequency, intensity, and muscle groups
/// to provide intelligent rest day recommendations that help prevent overtraining
/// and optimize recovery.
///
/// Example usage:
/// ```dart
/// final service = RestDaySuggestionService();
/// final suggestion = await service.suggestRestDay(workoutHistory);
///
/// if (suggestion.shouldRest) {
///   print('Recommendation: ${suggestion.reason}');
/// }
/// ```
class RestDaySuggestionService {
  /// Analyzes workout history and returns rest day suggestions.
  ///
  /// The algorithm considers:
  /// - Consecutive workout days
  /// - Workout intensity (volume and duration)
  /// - Time since last rest day
  /// - Overall fatigue indicators
  RestDaySuggestion suggestRestDay(List<WorkoutSession> recentWorkouts) {
    if (recentWorkouts.isEmpty) {
      return RestDaySuggestion(
        shouldRest: false,
        confidenceLevel: ConfidenceLevel.high,
        reason: 'No recent workout data available. Feel free to train!',
        daysUntilRecommendedRest: 0,
      );
    }

    // Sort workouts by date (most recent first)
    final sortedWorkouts = List<WorkoutSession>.from(recentWorkouts)
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    // Calculate metrics
    final consecutiveDays = _calculateConsecutiveDays(sortedWorkouts);
    final weeklyVolume = _calculateWeeklyVolume(sortedWorkouts);
    final avgDuration = _calculateAverageDuration(sortedWorkouts);
    final daysSinceLastWorkout = _daysSinceLastWorkout(sortedWorkouts);

    // Decision logic
    if (consecutiveDays >= 6) {
      return RestDaySuggestion(
        shouldRest: true,
        confidenceLevel: ConfidenceLevel.high,
        reason:
            'You\'ve trained for $consecutiveDays consecutive days. Your body needs recovery to grow stronger.',
        daysUntilRecommendedRest: 0,
      );
    }

    if (consecutiveDays >= 4 && weeklyVolume > 15) {
      return RestDaySuggestion(
        shouldRest: true,
        confidenceLevel: ConfidenceLevel.high,
        reason:
            'High training volume ($weeklyVolume workouts) with $consecutiveDays consecutive days. Take a rest to optimize recovery.',
        daysUntilRecommendedRest: 0,
      );
    }

    if (consecutiveDays >= 3 && avgDuration > 90) {
      return RestDaySuggestion(
        shouldRest: true,
        confidenceLevel: ConfidenceLevel.medium,
        reason:
            'Long workout sessions (avg ${avgDuration.round()} minutes) for $consecutiveDays days. Consider a rest day.',
        daysUntilRecommendedRest: 0,
      );
    }

    if (daysSinceLastWorkout >= 3) {
      return RestDaySuggestion(
        shouldRest: false,
        confidenceLevel: ConfidenceLevel.high,
        reason:
            'It\'s been $daysSinceLastWorkout days since your last workout. You\'re well-rested and ready to train!',
        daysUntilRecommendedRest: consecutiveDays >= 2 ? 1 : 2,
      );
    }

    if (consecutiveDays >= 2) {
      return RestDaySuggestion(
        shouldRest: false,
        confidenceLevel: ConfidenceLevel.medium,
        reason:
            'You\'ve trained for $consecutiveDays consecutive days. Consider a rest day after today\'s session.',
        daysUntilRecommendedRest: 1,
      );
    }

    return RestDaySuggestion(
      shouldRest: false,
      confidenceLevel: ConfidenceLevel.high,
      reason: 'Your training schedule looks balanced. Keep up the great work!',
      daysUntilRecommendedRest: consecutiveDays >= 1 ? 2 : 3,
    );
  }

  /// Calculates number of consecutive workout days.
  int _calculateConsecutiveDays(List<WorkoutSession> workouts) {
    if (workouts.isEmpty) return 0;

    int consecutive = 0;
    DateTime? lastDate;

    for (final workout in workouts) {
      if (workout.completedAt == null) continue;

      final workoutDate = DateTime(
        workout.completedAt!.year,
        workout.completedAt!.month,
        workout.completedAt!.day,
      );

      if (lastDate == null) {
        consecutive = 1;
        lastDate = workoutDate;
        continue;
      }

      final daysDiff = lastDate.difference(workoutDate).inDays;

      if (daysDiff == 1) {
        consecutive++;
        lastDate = workoutDate;
      } else {
        // Break in consecutive streak
        break;
      }
    }

    return consecutive;
  }

  /// Calculates total workouts in the last 7 days.
  int _calculateWeeklyVolume(List<WorkoutSession> workouts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return workouts
        .where((w) =>
            w.completedAt != null &&
            w.completedAt!.isAfter(weekAgo) &&
            w.completedAt!.isBefore(now))
        .length;
  }

  /// Calculates average workout duration in minutes.
  double _calculateAverageDuration(List<WorkoutSession> workouts) {
    final workoutsWithDuration = workouts
        .where((w) => w.durationMinutes != null && w.durationMinutes! > 0)
        .toList();

    if (workoutsWithDuration.isEmpty) return 0;

    final totalDuration = workoutsWithDuration
        .map((w) => w.durationMinutes!)
        .reduce((a, b) => a + b);

    return totalDuration / workoutsWithDuration.length;
  }

  /// Calculates days since the last completed workout.
  int _daysSinceLastWorkout(List<WorkoutSession> workouts) {
    if (workouts.isEmpty || workouts.first.completedAt == null) {
      return 999; // Large number to indicate no recent workouts
    }

    final now = DateTime.now();
    final lastWorkout = workouts.first.completedAt!;
    return now.difference(lastWorkout).inDays;
  }
}

/// Represents a rest day suggestion with reasoning.
class RestDaySuggestion {
  /// Whether the user should take a rest day.
  final bool shouldRest;

  /// Confidence level of the suggestion.
  final ConfidenceLevel confidenceLevel;

  /// Human-readable reason for the suggestion.
  final String reason;

  /// Number of days until a rest day is recommended.
  /// 0 means rest today, 1 means rest tomorrow, etc.
  final int daysUntilRecommendedRest;

  const RestDaySuggestion({
    required this.shouldRest,
    required this.confidenceLevel,
    required this.reason,
    required this.daysUntilRecommendedRest,
  });
}

/// Confidence level for rest day suggestions.
enum ConfidenceLevel {
  /// High confidence based on clear indicators.
  high,

  /// Medium confidence with some ambiguity.
  medium,

  /// Low confidence, more of a general guideline.
  low,
}
