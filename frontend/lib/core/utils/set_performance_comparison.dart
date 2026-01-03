import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

/// Utility for comparing set performance
class SetPerformanceComparison {
  /// Compare current set with previous workout's same set
  /// Returns:
  /// - 1 if improved (↑)
  /// - 0 if same (→)
  /// - -1 if declined (↓)
  /// - null if no comparison available
  static int? compareSetPerformance({
    required WorkoutSet currentSet,
    WorkoutSet? previousSet,
  }) {
    if (previousSet == null) return null;

    // Compare based on estimated 1RM first (most comprehensive)
    final current1RM = currentSet.calculated1RM;
    final previous1RM = previousSet.calculated1RM;

    if (current1RM != null && previous1RM != null) {
      // Consider a 1% difference as significant to avoid noise
      final threshold = previous1RM * 0.01;
      if (current1RM > previous1RM + threshold) return 1;
      if (current1RM < previous1RM - threshold) return -1;
      return 0;
    }

    // Fallback: compare weight
    if (currentSet.weightKg > previousSet.weightKg) return 1;
    if (currentSet.weightKg < previousSet.weightKg) return -1;

    // Weights are equal, compare reps
    if (currentSet.reps > previousSet.reps) return 1;
    if (currentSet.reps < previousSet.reps) return -1;

    return 0; // Exactly the same
  }

  /// Get trend icon based on comparison result
  static String getTrendIcon(int? comparison) {
    if (comparison == null) return '';
    if (comparison > 0) return '↑';
    if (comparison < 0) return '↓';
    return '→';
  }
}
