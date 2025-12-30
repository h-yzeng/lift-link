import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

/// Represents a complete workout session.
///
/// Contains multiple [ExercisePerformance]s and provides aggregate
/// statistics for the entire workout.
@freezed
class WorkoutSession with _$WorkoutSession {
  const WorkoutSession._(); // Required for custom getters

  const factory WorkoutSession({
    required String id,
    required String userId,
    required String title,
    String? notes,
    required DateTime startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    @Default([]) List<ExercisePerformance> exercises,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);

  /// Whether the workout is currently in progress
  bool get isInProgress => completedAt == null;

  /// Whether the workout has been completed
  bool get isCompleted => completedAt != null;

  /// Calculate duration. Uses stored value if completed,
  /// otherwise calculates from start time.
  int get actualDuration {
    if (durationMinutes != null) return durationMinutes!;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt).inMinutes;
  }

  /// Formats duration for display (e.g., "1h 23m")
  String get formattedDuration {
    final minutes = actualDuration;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Total number of exercises in this workout
  int get exerciseCount => exercises.length;

  /// Total number of sets across all exercises
  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSetsCount);
  }

  /// Total number of working sets (excluding warmups)
  int get totalWorkingSets {
    return exercises.fold(
        0, (sum, exercise) => sum + exercise.workingSetsCount,);
  }

  /// Total volume across all exercises
  double get totalVolume {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
  }

  /// Formats total volume for display
  String get formattedTotalVolume {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  /// Total reps across all exercises
  int get totalReps {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalReps);
  }

  /// Map of exercise names to their max 1RM (personal records for this workout)
  Map<String, double> get personalRecords {
    final records = <String, double>{};
    for (final exercise in exercises) {
      final maxOneRM = exercise.maxOneRM;
      if (maxOneRM != null) {
        records[exercise.exerciseName] = maxOneRM;
      }
    }
    return records;
  }

  /// Get the highest 1RM across all exercises in this workout
  double? get highestOneRM {
    final allOneRMs =
        exercises.map((e) => e.maxOneRM).whereType<double>().toList();
    if (allOneRMs.isEmpty) return null;
    return allOneRMs.reduce((a, b) => a > b ? a : b);
  }

  /// List of muscle groups worked in this session
  List<String> get muscleGroupsWorked {
    // This would need exercise data to be complete
    // For now, we'll derive from exercise names if possible
    return [];
  }

  /// Duration as a Duration object (for UI formatting)
  Duration? get duration {
    if (completedAt == null && durationMinutes == null) {
      // For in-progress workouts, calculate from start time
      return DateTime.now().difference(startedAt);
    }
    if (durationMinutes != null) {
      return Duration(minutes: durationMinutes!);
    }
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  /// Count of personal records in this workout
  /// For now, counts exercises that have a max 1RM value
  int get personalRecordsCount => personalRecords.length;
}
