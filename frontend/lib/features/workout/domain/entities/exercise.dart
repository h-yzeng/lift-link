import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Represents an exercise in the exercise library.
///
/// Can be either a system exercise (available to all users)
/// or a custom exercise created by a specific user.
@freezed
class Exercise with _$Exercise {
  const Exercise._(); // Required for custom getters

  const factory Exercise({
    required String id,
    required String name,
    String? description,
    required String muscleGroup,
    String? equipmentType,
    @Default(false) bool isCustom,
    String? createdBy, // User ID if custom exercise
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  /// Whether this is a system exercise (available to all)
  bool get isSystemExercise => !isCustom && createdBy == null;

  /// Whether this is a custom exercise created by a user
  bool get isUserExercise => isCustom && createdBy != null;

  /// Formatted muscle group for display (capitalize first letter)
  String get formattedMuscleGroup {
    if (muscleGroup.isEmpty) return '';
    return muscleGroup[0].toUpperCase() + muscleGroup.substring(1);
  }

  /// Formatted equipment type for display
  String get formattedEquipmentType {
    if (equipmentType == null || equipmentType!.isEmpty) return 'Any';
    return equipmentType![0].toUpperCase() + equipmentType!.substring(1);
  }
}

/// Common muscle groups used for exercises
abstract class MuscleGroups {
  static const String chest = 'chest';
  static const String back = 'back';
  static const String legs = 'legs';
  static const String shoulders = 'shoulders';
  static const String arms = 'arms';
  static const String core = 'core';

  static const List<String> all = [
    chest,
    back,
    legs,
    shoulders,
    arms,
    core,
  ];
}

/// Common equipment types
abstract class EquipmentTypes {
  static const String barbell = 'barbell';
  static const String dumbbell = 'dumbbell';
  static const String machine = 'machine';
  static const String cable = 'cable';
  static const String bodyweight = 'bodyweight';

  static const List<String> all = [
    barbell,
    dumbbell,
    machine,
    cable,
    bodyweight,
  ];
}
