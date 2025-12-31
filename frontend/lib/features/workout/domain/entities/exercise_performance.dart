import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

part 'exercise_performance.freezed.dart';
part 'exercise_performance.g.dart';

/// Represents the performance of a single exercise within a workout session.
///
/// Contains multiple [WorkoutSet]s and provides aggregate calculations
/// like max 1RM and total volume.
@freezed
class ExercisePerformance with _$ExercisePerformance {
  const ExercisePerformance._(); // Required for custom getters

  const factory ExercisePerformance({
    required String id,
    required String workoutSessionId,
    required String exerciseId,
    required String exerciseName, // Denormalized for display
    required int orderIndex,
    String? notes,
    @Default([]) List<WorkoutSet> sets,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ExercisePerformance;

  factory ExercisePerformance.fromJson(Map<String, dynamic> json) =>
      _$ExercisePerformanceFromJson(json);

  /// Get the highest 1RM across all non-warmup sets.
  ///
  /// Returns null if there are no valid 1RM calculations.
  double? get maxOneRM {
    final oneRMs = sets
        .where((set) => !set.isWarmup)
        .map((set) => set.calculated1RM)
        .whereType<double>()
        .toList();

    if (oneRMs.isEmpty) return null;
    return oneRMs.reduce((a, b) => a > b ? a : b);
  }

  /// Formats max 1RM for display
  String get formattedMaxOneRM {
    final max = maxOneRM;
    if (max == null) return 'N/A';
    return '${max.toStringAsFixed(1)} kg';
  }

  /// Total volume (sum of sets × reps × weight) including warmups.
  double get totalVolume {
    return sets.fold(0.0, (sum, set) => sum + set.volume);
  }

  /// Number of working sets (excluding warmups)
  int get workingSetsCount => sets.where((set) => !set.isWarmup).length;

  /// Number of warmup sets
  int get warmupSetsCount => sets.where((set) => set.isWarmup).length;

  /// Total number of sets
  int get totalSetsCount => sets.length;

  /// Total reps across all working sets
  int get totalReps {
    return sets
        .where((set) => !set.isWarmup)
        .fold(0, (sum, set) => sum + set.reps);
  }

  /// Average weight across working sets
  double? get averageWeight {
    final workingSets = sets.where((set) => !set.isWarmup).toList();
    if (workingSets.isEmpty) return null;
    final totalWeight = workingSets.fold(0.0, (sum, set) => sum + set.weightKg);
    return totalWeight / workingSets.length;
  }

  /// Heaviest weight lifted in working sets
  double? get maxWeight {
    final weights =
        sets.where((set) => !set.isWarmup).map((set) => set.weightKg).toList();
    if (weights.isEmpty) return null;
    return weights.reduce((a, b) => a > b ? a : b);
  }
}
