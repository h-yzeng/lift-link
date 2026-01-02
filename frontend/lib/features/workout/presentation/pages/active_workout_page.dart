import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/preferences/rest_timer_preference.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/rest_timer.dart';
import 'package:liftlink/features/workout/presentation/widgets/set_input_row.dart';
import 'package:liftlink/shared/utils/haptic_service.dart';
import 'package:liftlink/shared/widgets/shimmer_loading.dart';

/// Page for active workout tracking
class ActiveWorkoutPage extends ConsumerStatefulWidget {
  final WorkoutSession workout;

  const ActiveWorkoutPage({
    required this.workout,
    super.key,
  });

  @override
  ConsumerState<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends ConsumerState<ActiveWorkoutPage> {
  bool _isLoading = false;

  Future<void> _addExercise() async {
    final exercise = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseListPage(selectionMode: true),
      ),
    );

    if (exercise == null || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final useCase = ref.read(addExerciseToWorkoutUseCaseProvider);
      final result = await useCase(
        workoutSessionId: widget.workout.id,
        exerciseId: exercise['id']!,
        exerciseName: exercise['name']!,
      );

      result.fold(
        (failure) {
          HapticService.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (_) {
          HapticService.success();
          // Refresh the workout
          ref.invalidate(activeWorkoutProvider);
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSet(ExercisePerformance exercise) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final setNumber = exercise.sets.length + 1;
      final useCase = ref.read(addSetToExerciseUseCaseProvider);

      // For now, add an empty set that the user will fill in
      final result = await useCase(
        exercisePerformanceId: exercise.id,
        setNumber: setNumber,
        reps: 0,
        weightKg: 0.0,
      );

      result.fold(
        (failure) {
          HapticService.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (_) {
          HapticService.lightTap();
          ref.invalidate(activeWorkoutProvider);
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeWorkout(WorkoutSession currentWorkout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Workout?'),
        content: Text(
          'You completed ${currentWorkout.exerciseCount} exercises with ${currentWorkout.totalSets} sets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final useCase = ref.read(completeWorkoutUseCaseProvider);
      final result = await useCase(workoutSessionId: currentWorkout.id);

      result.fold(
        (failure) {
          HapticService.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to complete workout: ${failure.userMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (completedWorkout) {
          HapticService.success();
          if (mounted) {
            ref.invalidate(activeWorkoutProvider);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout completed!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(activeWorkoutProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    // Get unit preference, default to imperial
    final useImperialUnits = profileAsync.maybeWhen(
      data: (profile) => profile?.usesImperialUnits ?? true,
      orElse: () => true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
        actions: [
          // Rest Timer button
          Consumer(
            builder: (context, ref, _) {
              final defaultSeconds = ref.watch(defaultRestTimerSecondsProvider);
              return IconButton(
                icon: const Icon(Icons.timer),
                onPressed: () {
                  HapticService.selection();
                  showRestTimerBottomSheet(
                    context,
                    initialSeconds: defaultSeconds,
                  );
                },
                tooltip: 'Rest Timer (${RestTimerPresets.formatDuration(defaultSeconds)})',
              );
            },
          ),
          if (!_isLoading)
            Consumer(
              builder: (context, ref, child) {
                final workoutAsync = ref.watch(activeWorkoutProvider);
                return workoutAsync.maybeWhen(
                  data: (workout) {
                    if (workout == null) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: () => _completeWorkout(workout),
                      tooltip: 'Complete Workout',
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(
              child: Text('No active workout'),
            );
          }

          return Column(
            children: [
              // Workout stats header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Duration',
                      value: workout.formattedDuration,
                    ),
                    _StatItem(
                      label: 'Exercises',
                      value: '${workout.exerciseCount}',
                    ),
                    _StatItem(
                      label: 'Sets',
                      value: '${workout.totalSets}',
                    ),
                    _StatItem(
                      label: 'Volume',
                      value: UnitConversion.formatWeight(
                        workout.totalVolume,
                        useImperialUnits,
                      ),
                    ),
                  ],
                ),
              ),

              // Exercise list
              Expanded(
                child: workout.exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No exercises yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add an exercise to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: workout.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = workout.exercises[index];
                          return _ExerciseCard(
                            exercise: exercise,
                            useImperialUnits: useImperialUnits,
                            onAddSet: () => _addSet(exercise),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const WorkoutHistorySkeleton(itemCount: 2),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                HapticService.mediumTap();
                _addExercise();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final ExercisePerformance exercise;
  final bool useImperialUnits;
  final VoidCallback onAddSet;

  const _ExerciseCard({
    required this.exercise,
    required this.useImperialUnits,
    required this.onAddSet,
  });

  Future<void> _updateSet(
    WidgetRef ref,
    BuildContext context,
    String setId,
    int reps,
    double weightKg,
    bool isWarmup,
    double? rpe,
    int? rir,
  ) async {
    final useCase = ref.read(updateSetUseCaseProvider);
    final result = await useCase(
      setId: setId,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      rpe: rpe,
      rir: rir,
    );

    result.fold(
      (Failure failure) {
        HapticService.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        }
      },
      (_) {
        HapticService.lightTap();
        // Refresh the workout to show updated values
        ref.invalidate(activeWorkoutProvider);
      },
    );
  }

  Future<void> _deleteSet(
    WidgetRef ref,
    BuildContext context,
    String setId,
  ) async {
    final useCase = ref.read(deleteSetUseCaseProvider);
    final result = await useCase(setId: setId);

    result.fold(
      (Failure failure) {
        HapticService.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        }
      },
      (_) {
        HapticService.warning();
        // Refresh the workout to show updated values
        ref.invalidate(activeWorkoutProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.totalSetsCount} sets • ${exercise.totalReps} reps • ${UnitConversion.formatWeight(exercise.totalVolume, useImperialUnits)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (exercise.maxOneRM != null)
                  Chip(
                    label: Text(
                      'Max: ${UnitConversion.formatWeight(exercise.maxOneRM!, useImperialUnits)}',
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Exercise history (previous sessions)
            _ExerciseHistorySection(
              exerciseId: exercise.exerciseId,
              useImperialUnits: useImperialUnits,
            ),

            // Sets header
            if (exercise.sets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sets',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),

            // Sets list
            ...exercise.sets.map((set) {
              return SetInputRow(
                setNumber: set.setNumber,
                existingSet: set,
                useImperialUnits: useImperialUnits,
                onSave: (reps, weightKg, isWarmup, rpe, rir) {
                  _updateSet(
                    ref,
                    context,
                    set.id,
                    reps,
                    weightKg,
                    isWarmup,
                    rpe,
                    rir,
                  );
                },
                onDelete: () {
                  _deleteSet(ref, context, set.id);
                },
              );
            }),

            // Personal Record display
            if (exercise.maxOneRM != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Record: ${UnitConversion.formatWeight(exercise.maxOneRM!, useImperialUnits)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // Add set button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticService.lightTap();
                  onAddSet();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display exercise history (previous sessions)
class _ExerciseHistorySection extends ConsumerStatefulWidget {
  final String exerciseId;
  final bool useImperialUnits;

  const _ExerciseHistorySection({
    required this.exerciseId,
    required this.useImperialUnits,
  });

  @override
  ConsumerState<_ExerciseHistorySection> createState() =>
      _ExerciseHistorySectionState();
}

class _ExerciseHistorySectionState
    extends ConsumerState<_ExerciseHistorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      exerciseHistoryProvider(exerciseId: widget.exerciseId),
    );

    return historyAsync.when(
      data: (history) {
        if (!history.hasHistory) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse button
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Previous',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${history.sessions.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History sessions (collapsible)
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              ...history.sessions.map((session) {
                return _HistorySessionCard(
                  session: session,
                  useImperialUnits: widget.useImperialUnits,
                );
              }),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Card displaying a single previous workout session
class _HistorySessionCard extends StatelessWidget {
  final ExerciseHistorySession session;
  final bool useImperialUnits;

  const _HistorySessionCard({
    required this.session,
    required this.useImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.workoutTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                session.formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sets summary
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: session.sets.map((set) {
              final formattedWeight = UnitConversion.formatWeight(
                set.weightKg,
                useImperialUnits,
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: set.isWarmup
                      ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${set.reps} × $formattedWeight',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: set.isWarmup
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),

          // Session stats
          if (session.maxWeight != null || session.totalVolume > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (session.maxWeight != null) ...[
                  Icon(
                    Icons.fitness_center,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Max: ${UnitConversion.formatWeight(session.maxWeight!, useImperialUnits)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.scale,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Volume: ${UnitConversion.formatWeight(session.totalVolume, useImperialUnits)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
