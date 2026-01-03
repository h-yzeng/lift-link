import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/preferences/rest_timer_preference.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/active_workout/exercise_list_section.dart';
import 'package:liftlink/features/workout/presentation/widgets/active_workout/workout_summary_section.dart';
import 'package:liftlink/features/workout/presentation/widgets/rest_timer.dart';
import 'package:liftlink/shared/utils/haptic_service.dart';
import 'package:liftlink/shared/widgets/shimmer_loading.dart';

/// Provider for active workout page loading state
final activeWorkoutLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

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

  Future<void> _addExercise() async {
    final exercise = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseListPage(selectionMode: true),
      ),
    );

    if (exercise == null || !mounted) return;

    ref.read(activeWorkoutLoadingProvider.notifier).state = true;

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
        ref.read(activeWorkoutLoadingProvider.notifier).state = false;
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

    ref.read(activeWorkoutLoadingProvider.notifier).state = true;

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
        ref.read(activeWorkoutLoadingProvider.notifier).state = false;
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
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(activeWorkoutLoadingProvider);
              if (isLoading) return const SizedBox.shrink();

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
              WorkoutSummarySection(
                workout: workout,
                useImperialUnits: useImperialUnits,
              ),

              // Exercise list
              ExerciseListSection(
                workout: workout,
                useImperialUnits: useImperialUnits,
                onAddExercise: _addExercise,
              ),
            ],
          );
        },
        loading: () => const WorkoutHistorySkeleton(itemCount: 2),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final isLoading = ref.watch(activeWorkoutLoadingProvider);
          if (isLoading) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              HapticService.mediumTap();
              _addExercise();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          );
        },
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
