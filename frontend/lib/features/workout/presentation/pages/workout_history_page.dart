import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:liftlink/features/workout/presentation/providers/paginated_workout_history_provider.dart';
import 'package:liftlink/features/workout/presentation/widgets/workout_summary_card.dart';
import 'package:liftlink/shared/widgets/shimmer_loading.dart';

/// Page displaying workout history with filtering options
class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedWorkoutHistoryProvider.notifier).loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final useImperialUnits = profileAsync.valueOrNull?.usesImperialUnits ?? true;

    final paginatedState = ref.watch(paginatedWorkoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showDateFilter,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedWorkoutHistoryProvider.notifier).refresh();
        },
        child: _buildBody(paginatedState, useImperialUnits, theme),
      ),
    );
  }

  Widget _buildBody(
    PaginatedWorkoutHistoryState state,
    bool useImperialUnits,
    ThemeData theme,
  ) {
    if (state.workouts.isEmpty && state.isLoading) {
      return const WorkoutHistorySkeleton();
    }

    if (state.workouts.isEmpty && state.error != null) {
      return _buildErrorState(state.error!, theme);
    }

    if (state.workouts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildWorkoutList(state, useImperialUnits);
  }

  Widget _buildWorkoutList(
    PaginatedWorkoutHistoryState state,
    bool useImperialUnits,
  ) {
    final workouts = state.workouts;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: workouts.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show workout cards
        if (index < workouts.length) {
          final workout = workouts[index];
          return WorkoutSummaryCard(
            workout: workout,
            useImperialUnits: useImperialUnits,
            onTap: () => _navigateToWorkoutDetail(workout),
          );
        }

        // Show "Load More" button at the end
        return Padding(
          padding: const EdgeInsets.all(16),
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: () {
                    ref
                        .read(paginatedWorkoutHistoryProvider.notifier)
                        .loadNextPage();
                  },
                  child: const Text('Load More'),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDateRange != null
                  ? 'No workouts in selected date range'
                  : 'No workouts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDateRange != null
                  ? 'Try adjusting your date filter'
                  : 'Start a workout to see your history here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.clear),
                label: const Text('Clear filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load workout history',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(paginatedWorkoutHistoryProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateFilter() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;

    final initialRange = _selectedDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final result = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select date range',
      cancelText: 'Clear',
      confirmText: 'Apply',
      saveText: 'Apply',
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
      });
      // Reload with new date filter
      ref.read(paginatedWorkoutHistoryProvider.notifier).loadFirstPage(
            startDate: result.start,
            endDate: result.end,
          );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    // Reload without date filter
    ref.read(paginatedWorkoutHistoryProvider.notifier).loadFirstPage();
  }

  void _navigateToWorkoutDetail(WorkoutSession workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailPage(workout: workout),
      ),
    );
  }
}
