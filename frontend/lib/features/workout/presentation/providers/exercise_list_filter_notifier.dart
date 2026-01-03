import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_list_filter_state.dart';

part 'exercise_list_filter_notifier.g.dart';

/// StateNotifier for managing exercise list filter state.
@riverpod
class ExerciseListFilterNotifier extends _$ExerciseListFilterNotifier {
  @override
  ExerciseListFilterState build() {
    return const ExerciseListFilterState();
  }

  void setMuscleGroup(String? muscleGroup) {
    state = state.copyWith(selectedMuscleGroup: muscleGroup);
  }

  void setEquipmentType(String? equipmentType) {
    state = state.copyWith(selectedEquipmentType: equipmentType);
  }

  void setShowCustomOnly(bool showCustomOnly) {
    state = state.copyWith(showCustomOnly: showCustomOnly);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      isSearching: query.isNotEmpty,
    );
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      isSearching: false,
    );
  }

  void clearAll() {
    state = const ExerciseListFilterState();
  }
}
