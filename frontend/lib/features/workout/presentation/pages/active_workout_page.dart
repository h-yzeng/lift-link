import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
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

  Future<void> _completeWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Workout?'),
        content: Text(
          'You completed ${widget.workout.exerciseCount} exercises with ${widget.workout.totalSets} sets.',
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
      final result = await useCase(workoutSessionId: widget.workout.id);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (completedWorkout) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Workout completed!')),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _completeWorkout,
              tooltip: 'Complete Workout',
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
                      value: workout.formattedTotalVolume,
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

class _ExerciseCard extends StatelessWidget {
  final ExercisePerformance exercise;
  final VoidCallback onAddSet;

  const _ExerciseCard({
    required this.exercise,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
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
                        '${exercise.totalSetsCount} sets • ${exercise.totalReps} reps • ${exercise.totalVolume.toStringAsFixed(0)} kg',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (exercise.maxOneRM != null)
                  Chip(
                    label: Text('Max: ${exercise.formattedMaxOneRM}'),
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
