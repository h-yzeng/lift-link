import 'package:freezed_annotation/freezed_annotation.dart';

part 'undo_action.freezed.dart';
part 'undo_action.g.dart';

/// Types of undo actions
enum UndoActionType { deleteSet, removeExercise, deleteWorkout }

/// Represents an action that can be undone
@freezed
abstract class UndoAction with _$UndoAction {
  const factory UndoAction({
    required String id,
    required UndoActionType type,
    required String description,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    @Default(false) bool executed,
  }) = _UndoAction;

  factory UndoAction.fromJson(Map<String, dynamic> json) =>
      _$UndoActionFromJson(json);
}

/// Factory methods for creating specific undo actions
extension UndoActionFactory on UndoAction {
  /// Create an undo action for deleting a set
  static UndoAction deleteSet({
    required String setId,
    required String exercisePerformanceId,
    required int setNumber,
    required double weight,
    required int reps,
    String? notes,
  }) {
    return UndoAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: UndoActionType.deleteSet,
      description: 'Delete set $setNumber ($reps reps @ $weight lbs)',
      data: {
        'setId': setId,
        'exercisePerformanceId': exercisePerformanceId,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'notes': notes,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create an undo action for removing an exercise from a workout
  static UndoAction removeExercise({
    required String exercisePerformanceId,
    required String workoutSessionId,
    required String exerciseName,
    required int orderIndex,
    required List<Map<String, dynamic>> sets,
  }) {
    return UndoAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: UndoActionType.removeExercise,
      description: 'Remove $exerciseName from workout',
      data: {
        'exercisePerformanceId': exercisePerformanceId,
        'workoutSessionId': workoutSessionId,
        'exerciseName': exerciseName,
        'orderIndex': orderIndex,
        'sets': sets,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create an undo action for deleting a workout
  static UndoAction deleteWorkout({
    required String workoutSessionId,
    required String title,
    required Map<String, dynamic> workoutData,
  }) {
    return UndoAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: UndoActionType.deleteWorkout,
      description: 'Delete workout: $title',
      data: {
        'workoutSessionId': workoutSessionId,
        'title': title,
        'workoutData': workoutData,
      },
      createdAt: DateTime.now(),
    );
  }
}
