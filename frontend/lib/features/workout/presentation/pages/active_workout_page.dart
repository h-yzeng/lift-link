import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/set_input_row.dart';

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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (_) {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (_) {
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExercise,
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
  ) async {
    final useCase = ref.read(updateSetUseCaseProvider);
    final result = await useCase(
      setId: setId,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      rpe: rpe,
    );

    result.fold(
      (Failure failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        }
      },
      (_) {
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
                onSave: (reps, weightKg, isWarmup, rpe) {
                  _updateSet(
                    ref,
                    context,
                    set.id,
                    reps,
                    weightKg,
                    isWarmup,
                    rpe,
                  );
                },
              );
            }),

            // Add set button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddSet,
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
