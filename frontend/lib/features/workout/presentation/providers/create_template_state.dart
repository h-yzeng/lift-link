import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';

part 'create_template_state.freezed.dart';

/// Immutable state for template creation.
@freezed
class CreateTemplateState with _$CreateTemplateState {
  const factory CreateTemplateState({
    @Default([]) List<TemplateExercise> exercises,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _CreateTemplateState;

  const CreateTemplateState._();

  /// Whether any exercises have been added
  bool get hasExercises => exercises.isNotEmpty;
}
