import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
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
  final int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final useImperialUnits = profileAsync.valueOrNull?.usesImperialUnits ?? true;

    final historyAsync = ref.watch(
      workoutHistoryProvider(
        limit: _pageSize,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      ),
    );

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
          ref.invalidate(workoutHistoryProvider);
        },
        child: historyAsync.when(
          data: (workouts) => _buildWorkoutList(workouts, useImperialUnits),
          loading: () => const WorkoutHistorySkeleton(),
          error: (error, stack) => _buildErrorState(error, theme),
        ),
      ),
    );
  }

  Widget _buildWorkoutList(List<WorkoutSession> workouts, bool useImperialUnits) {
    if (workouts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return WorkoutSummaryCard(
          workout: workout,
          useImperialUnits: useImperialUnits,
          onTap: () => _navigateToWorkoutDetail(workout),
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
              onPressed: () => ref.invalidate(workoutHistoryProvider),
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
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
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
