import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_list_filter_state.freezed.dart';

/// Immutable state for exercise list filtering and search.
@freezed
abstract class ExerciseListFilterState with _$ExerciseListFilterState {
  const factory ExerciseListFilterState({
    String? selectedMuscleGroup,
    String? selectedEquipmentType,
    @Default(false) bool showCustomOnly,
    @Default(false) bool isSearching,
    @Default('') String searchQuery,
  }) = _ExerciseListFilterState;

  const ExerciseListFilterState._();

  /// Whether any filter is active
  bool get hasActiveFilters =>
      selectedMuscleGroup != null ||
      selectedEquipmentType != null ||
      showCustomOnly ||
      isSearching;

  /// Clear all filters and return to default state
  ExerciseListFilterState clearAll() {
    return const ExerciseListFilterState();
  }
}
