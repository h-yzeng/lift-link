import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/set_input_row.dart';
import 'package:liftlink/features/workout/presentation/utils/rest_timer_utils.dart';
import 'package:liftlink/shared/utils/haptic_service.dart';

/// Displays the list of exercises in the active workout
class ExerciseListSection extends ConsumerWidget {
  final WorkoutSession workout;
  final bool useImperialUnits;
  final VoidCallback onAddExercise;

  const ExerciseListSection({
    required this.workout,
    required this.useImperialUnits,
    required this.onAddExercise,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workout.exercises.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No exercises yet',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add exercises to your workout.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: workout.exercises.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final exercise = workout.exercises[index];
          return _ExerciseCard(
            exercise: exercise,
            useImperialUnits: useImperialUnits,
            context: context,
          );
        },
      ),
    );
  }
}

/// Card displaying a single exercise with its sets
class _ExerciseCard extends ConsumerWidget {
  final ExercisePerformance exercise;
  final bool useImperialUnits;
  final BuildContext context;

  const _ExerciseCard({
    required this.exercise,
    required this.useImperialUnits,
    required this.context,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exerciseHistoryAsync = ref.watch(
      exerciseHistoryProvider(exerciseId: exercise.exerciseId, limit: 1),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // PR badge if available
                if (exercise.maxWeight != null)
                  Semantics(
                    label:
                        'Personal record: ${UnitConversion.formatWeight(exercise.maxWeight!, useImperialUnits)}',
                    child: Chip(
                      avatar: const ExcludeSemantics(
                        child: Icon(Icons.emoji_events, size: 16),
                      ),
                      label: Text(
                        'PR: ${UnitConversion.formatWeight(exercise.maxWeight!, useImperialUnits)}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Previous performance (if available)
            exerciseHistoryAsync.when(
              data: (history) {
                if (!history.hasHistory) return const SizedBox.shrink();
                final lastSession = history.lastSession;
                if (lastSession == null) return const SizedBox.shrink();
                return _buildPreviousPerformance(context, lastSession);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Sets list
            if (exercise.sets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...exercise.sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SetInputRow(
                    key: ValueKey('${exercise.id}_set_${set.id}'),
                    setNumber: index + 1,
                    existingSet: set,
                    useImperialUnits: useImperialUnits,
                    onSave: (reps, weight, isWarmup, rpe, rir) => _updateSet(
                        ref, set.id, reps, weight, isWarmup, rpe, rir),
                    onDelete: () => _deleteSet(ref, set.id),
                  ),
                );
              }),
            ],

            // Add set button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(ref),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousPerformance(
    BuildContext context,
    ExerciseHistorySession session,
  ) {
    final workingSets = session.sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return const SizedBox.shrink();

    final avgReps = workingSets.fold<int>(
          0,
          (sum, set) => sum + set.reps,
        ) /
        workingSets.length;
    final avgWeight = workingSets.fold<double>(
          0.0,
          (sum, set) => sum + set.weightKg,
        ) /
        workingSets.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Previous:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                session.formattedDate,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${workingSets.length} sets × ${avgReps.toStringAsFixed(0)} reps × ${UnitConversion.formatWeight(avgWeight, useImperialUnits)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _addSet(WidgetRef ref) async {
    HapticService.selection();
    final useCase = ref.read(addSetToExerciseUseCaseProvider);
    final setNumber = exercise.sets.length + 1;

    final result = await useCase(
      exercisePerformanceId: exercise.id,
      setNumber: setNumber,
      reps: 0,
      weightKg: 0.0,
    );

    result.fold(
      (failure) => HapticService.error(),
      (_) {
        HapticService.success();
        ref.invalidate(activeWorkoutProvider);
      },
    );
  }

  Future<void> _updateSet(
    WidgetRef ref,
    String setId,
    int reps,
    double weight,
    bool isWarmup,
    double? rpe,
    int? rir,
  ) async {
    final useCase = ref.read(updateSetUseCaseProvider);
    final result = await useCase(
      setId: setId,
      reps: reps,
      weightKg: weight,
      isWarmup: isWarmup,
      rpe: rpe,
      rir: rir,
    );

    result.fold(
      (failure) => HapticService.error(),
      (_) {
        HapticService.success();
        ref.invalidate(activeWorkoutProvider);
        // Auto-start rest timer if enabled (only for non-warmup sets)
        if (!isWarmup && context.mounted) {
          maybeAutoStartRestTimer(context: context, ref: ref);
        }
      },
    );
  }

  Future<void> _deleteSet(WidgetRef ref, String setId) async {
    HapticService.selection();
    final useCase = ref.read(deleteSetUseCaseProvider);
    final result = await useCase(setId: setId);

    result.fold(
      (failure) => HapticService.error(),
      (_) {
        HapticService.success();
        ref.invalidate(activeWorkoutProvider);
      },
    );
  }
}
