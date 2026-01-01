import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

/// State for paginated workout history
class PaginatedWorkoutHistoryState {
  final List<WorkoutSession> workouts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PaginatedWorkoutHistoryState({
    required this.workouts,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.currentPage = 0,
  });

  PaginatedWorkoutHistoryState copyWith({
    List<WorkoutSession>? workouts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return PaginatedWorkoutHistoryState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for paginated workout history
class PaginatedWorkoutHistoryNotifier
    extends StateNotifier<PaginatedWorkoutHistoryState> {
  PaginatedWorkoutHistoryNotifier(this.ref)
      : super(
          const PaginatedWorkoutHistoryState(
            workouts: [],
            isLoading: false,
            hasMore: true,
          ),
        );

  final Ref ref;
  static const int _pageSize = 20;

  DateTime? _startDate;
  DateTime? _endDate;

  /// Load the first page of workouts
  Future<void> loadFirstPage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;

    state = state.copyWith(
      isLoading: true,
      error: null,
      workouts: [],
      currentPage: 0,
      hasMore: true,
    );

    await _loadPage(0);
  }

  /// Load the next page of workouts
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    await _loadPage(state.currentPage + 1);
  }

  /// Refresh the current data
  Future<void> refresh() async {
    await loadFirstPage(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _loadPage(int page) async {
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

      final useCase = ref.read(getWorkoutHistoryUseCaseProvider);
      final offset = page * _pageSize;
      final result = await useCase(
        userId: user.id,
        limit: _pageSize,
        offset: offset,
        startDate: _startDate,
        endDate: _endDate,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.userMessage,
          );
        },
        (newWorkouts) {
          final allWorkouts =
              page == 0 ? newWorkouts : [...state.workouts, ...newWorkouts];

          state = state.copyWith(
            workouts: allWorkouts,
            isLoading: false,
            hasMore: newWorkouts.length >= _pageSize,
            currentPage: page,
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

/// Provider for paginated workout history
final paginatedWorkoutHistoryProvider = StateNotifierProvider<
    PaginatedWorkoutHistoryNotifier, PaginatedWorkoutHistoryState>((ref) {
  return PaginatedWorkoutHistoryNotifier(ref);
});
