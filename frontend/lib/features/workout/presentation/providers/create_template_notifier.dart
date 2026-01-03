import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/presentation/providers/create_template_state.dart';

part 'create_template_notifier.g.dart';

/// StateNotifier for managing template creation state.
@riverpod
class CreateTemplateNotifier extends _$CreateTemplateNotifier {
  @override
  CreateTemplateState build() {
    return const CreateTemplateState();
  }

  void addExercise(TemplateExercise exercise) {
    state = state.copyWith(
      exercises: [...state.exercises, exercise],
    );
  }

  void removeExercise(int index) {
    if (index < 0 || index >= state.exercises.length) return;

    final newExercises = [...state.exercises];
    newExercises.removeAt(index);
    state = state.copyWith(exercises: newExercises);
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.exercises.length) return;

    var adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }

    final newExercises = [...state.exercises];
    final exercise = newExercises.removeAt(oldIndex);
    newExercises.insert(adjustedNewIndex, exercise);
    state = state.copyWith(exercises: newExercises);
  }

  void setSaving(bool isSaving) {
    state = state.copyWith(isSaving: isSaving);
  }

  void setError(String? errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }

  void reset() {
    state = const CreateTemplateState();
  }
}
