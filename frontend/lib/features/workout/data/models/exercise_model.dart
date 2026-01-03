import 'package:drift/drift.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Extension to convert Drift ExerciseEntity to domain Exercise
extension ExerciseModelMapper on ExerciseEntity {
  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description,
      muscleGroup: muscleGroup,
      equipmentType: equipmentType,
      isCustom: isCustom,
      createdBy: createdBy,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain Exercise to Drift companion
extension ExerciseToDrift on Exercise {
  ExercisesCompanion toCompanion() {
    return ExercisesCompanion.insert(
      id: id,
      name: name,
      description: Value(description),
      muscleGroup: muscleGroup,
      equipmentType: Value(equipmentType),
      isCustom: Value(isCustom),
      createdBy: Value(createdBy),
      lastUsedAt: Value(lastUsedAt),
      usageCount: Value(usageCount),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Helper to convert from Supabase JSON to domain Exercise
Exercise exerciseFromJson(Map<String, dynamic> json) {
  return Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    muscleGroup: json['muscle_group'] as String,
    equipmentType: json['equipment_type'] as String?,
    isCustom: json['is_custom'] as bool? ?? false,
    createdBy: json['created_by'] as String?,
    lastUsedAt: json['last_used_at'] != null
        ? DateTime.parse(json['last_used_at'] as String)
        : null,
    usageCount: json['usage_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Helper to convert domain Exercise to Supabase JSON
Map<String, dynamic> exerciseToJson(Exercise exercise) {
  return {
    'id': exercise.id,
    'name': exercise.name,
    'description': exercise.description,
    'muscle_group': exercise.muscleGroup,
    'equipment_type': exercise.equipmentType,
    'is_custom': exercise.isCustom,
    'created_by': exercise.createdBy,
    'created_at': exercise.createdAt.toIso8601String(),
    'updated_at': exercise.updatedAt.toIso8601String(),
  };
}
