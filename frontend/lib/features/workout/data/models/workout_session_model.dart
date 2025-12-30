import 'package:drift/drift.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Extension to convert Drift WorkoutSessionEntity to domain WorkoutSession
/// Note: Exercises must be populated separately via joins
extension WorkoutSessionModelMapper on WorkoutSessionEntity {
  WorkoutSession toEntity({List<ExercisePerformance> exercises = const []}) {
    return WorkoutSession(
      id: id,
      userId: userId,
      title: title,
      notes: notes,
      startedAt: startedAt,
      completedAt: completedAt,
      durationMinutes: durationMinutes,
      exercises: exercises,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain WorkoutSession to Drift companion
extension WorkoutSessionToDrift on WorkoutSession {
  WorkoutSessionsCompanion toCompanion({bool isPendingSync = false}) {
    return WorkoutSessionsCompanion.insert(
      id: id,
      userId: userId,
      title: title,
      notes: Value(notes),
      startedAt: startedAt,
      completedAt: Value(completedAt),
      durationMinutes: Value(durationMinutes),
      isPendingSync: Value(isPendingSync),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Helper to convert from Supabase JSON to domain WorkoutSession
WorkoutSession workoutSessionFromJson(
  Map<String, dynamic> json, {
  List<ExercisePerformance> exercises = const [],
}) {
  return WorkoutSession(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    notes: json['notes'] as String?,
    startedAt: DateTime.parse(json['started_at'] as String),
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    durationMinutes: json['duration_minutes'] as int?,
    exercises: exercises,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Helper to convert domain WorkoutSession to Supabase JSON
Map<String, dynamic> workoutSessionToJson(WorkoutSession session) {
  return {
    'id': session.id,
    'user_id': session.userId,
    'title': session.title,
    'notes': session.notes,
    'started_at': session.startedAt.toIso8601String(),
    'completed_at': session.completedAt?.toIso8601String(),
    'duration_minutes': session.durationMinutes,
    'created_at': session.createdAt.toIso8601String(),
    'updated_at': session.updatedAt.toIso8601String(),
  };
}
