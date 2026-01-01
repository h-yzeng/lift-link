import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_history.freezed.dart';
part 'exercise_history.g.dart';

/// Represents a historical set from a previous workout session.
///
/// Used to show users their previous performance when adding sets
/// to an exercise in an active workout.
@freezed
class HistoricalSet with _$HistoricalSet {
  const factory HistoricalSet({
    required int setNumber,
    required int reps,
    required double weightKg,
    required bool isWarmup,
    double? rpe,
  }) = _HistoricalSet;

  factory HistoricalSet.fromJson(Map<String, dynamic> json) =>
      _$HistoricalSetFromJson(json);
}

/// Represents a previous workout session for a specific exercise.
///
/// Contains the workout metadata and all sets performed for that exercise.
@freezed
class ExerciseHistorySession with _$ExerciseHistorySession {
  const ExerciseHistorySession._();

  const factory ExerciseHistorySession({
    required String workoutSessionId,
    required String workoutTitle,
    required DateTime completedAt,
    @Default([]) List<HistoricalSet> sets,
  }) = _ExerciseHistorySession;

  factory ExerciseHistorySession.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistorySessionFromJson(json);

  /// Format the completion date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    }
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? "month" : "months"} ago';
  }

  /// Get the max weight used in this session (excluding warmups)
  double? get maxWeight {
    final workingSets = sets.where((s) => !s.isWarmup);
    if (workingSets.isEmpty) return null;
    return workingSets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
  }

  /// Get the total volume for this session (weight * reps, excluding warmups)
  double get totalVolume {
    return sets
        .where((s) => !s.isWarmup)
        .fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));
  }
}

/// Represents the complete exercise history for a specific exercise.
///
/// Contains up to N previous sessions (typically 3) to show the user
/// their recent performance history.
@freezed
class ExerciseHistory with _$ExerciseHistory {
  const ExerciseHistory._();

  const factory ExerciseHistory({
    required String exerciseId,
    required String userId,
    @Default([]) List<ExerciseHistorySession> sessions,
  }) = _ExerciseHistory;

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryFromJson(json);

  /// Whether there is any history available
  bool get hasHistory => sessions.isNotEmpty;

  /// Get the most recent session
  ExerciseHistorySession? get lastSession =>
      sessions.isNotEmpty ? sessions.first : null;
}
