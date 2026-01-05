import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_template.freezed.dart';
part 'workout_template.g.dart';

/// Represents a workout template that can be reused.
@freezed
abstract class WorkoutTemplate with _$WorkoutTemplate {
  const WorkoutTemplate._();

  const factory WorkoutTemplate({
    required String id,
    required String userId,
    required String name,
    String? description,
    required List<TemplateExercise> exercises,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkoutTemplate;

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);

  /// Total number of exercises in this template
  int get exerciseCount => exercises.length;

  /// Total number of sets across all exercises
  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  }
}

/// Represents an exercise within a workout template.
@freezed
abstract class TemplateExercise with _$TemplateExercise {
  const factory TemplateExercise({
    required String exerciseId,
    required String exerciseName,
    required int sets,
    int? targetReps,
    double? targetWeight,
    String? notes,
  }) = _TemplateExercise;

  factory TemplateExercise.fromJson(Map<String, dynamic> json) =>
      _$TemplateExerciseFromJson(json);
}
