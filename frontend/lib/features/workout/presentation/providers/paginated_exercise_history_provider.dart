import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

/// State for paginated exercise history with lazy loading support.
///
/// This class manages the state of exercise history data as it's loaded
/// incrementally, allowing the UI to display results progressively.
class PaginatedExerciseHistoryState {
  final ExerciseHistory? history;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentLimit;

  const PaginatedExerciseHistoryState({
    this.history,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.currentLimit = 3,
  });

  PaginatedExerciseHistoryState copyWith({
    ExerciseHistory? history,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentLimit,
  }) {
    return PaginatedExerciseHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentLimit: currentLimit ?? this.currentLimit,
    );
  }
}

/// Notifier for paginated exercise history with lazy loading.
///
/// This notifier manages incremental loading of exercise history data,
/// starting with a small initial set and loading more as requested.
///
/// Example usage:
/// ```dart
/// // Load initial history
/// ref.read(paginatedExerciseHistoryProvider(exerciseId).notifier).loadInitial();
///
/// // Load more history
/// ref.read(paginatedExerciseHistoryProvider(exerciseId).notifier).loadMore();
/// ```
class PaginatedExerciseHistoryNotifier
    extends StateNotifier<PaginatedExerciseHistoryState> {
  PaginatedExerciseHistoryNotifier(
    this.ref,
    this.exerciseId,
  ) : super(
          const PaginatedExerciseHistoryState(
            isLoading: false,
            hasMore: true,
          ),
        );

  final Ref ref;
  final String exerciseId;
  static const int _initialLimit = 3;
  static const int _incrementSize = 5;
  static const int _maxLimit = 50; // Prevent loading too much data

  /// Load the initial set of exercise history (last 3 sessions).
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentLimit: _initialLimit,
    );

    await _loadHistory(_initialLimit);
  }

  /// Load more exercise history sessions incrementally.
  ///
  /// Increases the limit by [_incrementSize] each call until [_maxLimit] is reached.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final newLimit = state.currentLimit + _incrementSize;
    if (newLimit > _maxLimit) {
      state = state.copyWith(hasMore: false);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentLimit: newLimit,
    );

    await _loadHistory(newLimit);
  }

  /// Refresh the current history data.
  Future<void> refresh() async {
    await _loadHistory(state.currentLimit);
  }

  Future<void> _loadHistory(int limit) async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
          hasMore: false,
        );
        return;
      }

      final useCase = ref.read(getExerciseHistoryUseCaseProvider);
      final result = await useCase(
        userId: user.id,
        exerciseId: exerciseId,
        limit: limit,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.userMessage,
          );
        },
        (history) {
          // Check if we've loaded all available data
          final hasMore = history.sessions.length >= limit && limit < _maxLimit;

          state = state.copyWith(
            history: history,
            isLoading: false,
            hasMore: hasMore,
            currentLimit: limit,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Family provider for paginated exercise history.
///
/// Creates a separate paginated history state for each exercise ID,
/// enabling lazy loading of exercise-specific workout history.
///
/// Usage:
/// ```dart
/// final historyState = ref.watch(paginatedExerciseHistoryProvider('exercise-123'));
/// if (historyState.hasMore) {
///   ref.read(paginatedExerciseHistoryProvider('exercise-123').notifier).loadMore();
/// }
/// ```
final paginatedExerciseHistoryProvider = StateNotifierProvider.family<
    PaginatedExerciseHistoryNotifier,
    PaginatedExerciseHistoryState,
    String>((ref, exerciseId) {
  final notifier = PaginatedExerciseHistoryNotifier(ref, exerciseId);
  // Auto-load initial history
  Future.microtask(() => notifier.loadInitial());
  return notifier;
});
