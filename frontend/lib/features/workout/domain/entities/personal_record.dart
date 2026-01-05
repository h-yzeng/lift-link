import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_record.freezed.dart';
part 'personal_record.g.dart';

/// Represents a personal record for an exercise.
///
/// Tracks the best performance (highest 1RM) for a specific exercise.
@freezed
abstract class PersonalRecord with _$PersonalRecord {
  const PersonalRecord._();

  const factory PersonalRecord({
    required String exerciseId,
    required String exerciseName,
    required String userId,
    required double weight,
    required int reps,
    required double oneRepMax,
    required DateTime achievedAt,
    required String workoutId,
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);

  /// Formatted weight for display
  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';

  /// Formatted 1RM for display
  String get formatted1RM => '${oneRepMax.toStringAsFixed(1)} kg';
}
