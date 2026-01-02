import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

/// Represents a single set within an exercise performance.
///
/// Contains the weight, reps, and metadata for a single set.
/// The 1RM is calculated client-side only using the Epley Formula.
@freezed
class WorkoutSet with _$WorkoutSet {
  const WorkoutSet._(); // Required for custom getters

  const factory WorkoutSet({
    required String id,
    required String exercisePerformanceId,
    required int setNumber,
    required int reps,
    required double weightKg,
    @Default(false) bool isWarmup,
    @Default(false) bool isDropset,
    double? rpe, // Rate of Perceived Exertion (0-10)
    int? rir, // Reps in Reserve (0-10)
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);

  /// Calculates estimated 1RM using the Epley Formula.
  ///
  /// Formula: weight × (1 + reps/30)
  ///
  /// Returns null for:
  /// - Warmup sets
  /// - Zero weight or zero reps
  /// - Very high rep ranges (>30) where the formula becomes unreliable
  double? get calculated1RM {
    if (isWarmup) return null;
    if (weightKg <= 0 || reps <= 0) return null;
    if (reps > 30) return null; // Formula unreliable for high reps

    return weightKg * (1 + reps / 30);
  }

  /// Formats 1RM for display (e.g., "125.5 kg")
  String get formatted1RM {
    final oneRM = calculated1RM;
    if (oneRM == null) return 'N/A';
    return '${oneRM.toStringAsFixed(1)} kg';
  }

  /// Returns true if this is a working set (not warmup)
  bool get isWorkingSet => !isWarmup;

  /// Returns the volume for this set (weight × reps)
  double get volume => weightKg * reps;

  /// Formats weight for display
  String get formattedWeight => '${weightKg.toStringAsFixed(1)} kg';

  /// Formats RPE for display (e.g., "RPE 8.5")
  String? get formattedRpe {
    if (rpe == null) return null;
    return 'RPE ${rpe!.toStringAsFixed(1)}';
  }

  /// Formats RIR for display (e.g., "RIR 2")
  String? get formattedRir {
    if (rir == null) return null;
    return 'RIR $rir';
  }
}
