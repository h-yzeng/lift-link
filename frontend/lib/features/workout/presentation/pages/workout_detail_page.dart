import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/presentation/pages/active_workout_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/shared/utils/haptic_service.dart';

/// Page displaying detailed view of a completed workout
class WorkoutDetailPage extends ConsumerWidget {
  final WorkoutSession workout;

  const WorkoutDetailPage({required this.workout, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final useImperialUnits =
        profileAsync.valueOrNull?.usesImperialUnits ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
        actions: [
          Semantics(
            label: 'Start new workout with same exercises',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => _repeatWorkout(context, ref),
              tooltip: 'Repeat this workout',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, useImperialUnits),
            const Divider(height: 1),
            _buildExercisesList(context, theme, useImperialUnits),
            if (workout.notes != null && workout.notes!.isNotEmpty) ...[
              const Divider(height: 1),
              _buildNotesSection(context, theme),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _repeatWorkout(BuildContext context, WidgetRef ref) async {
    HapticService.lightTap();

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to start a workout')),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Starting workout...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final startWorkoutUseCase = ref.read(startWorkoutUseCaseProvider);
    final addExerciseUseCase = ref.read(addExerciseToWorkoutUseCaseProvider);

    // Start a new workout with the same title
    final workoutResult = await startWorkoutUseCase(
      userId: user.id,
      title: workout.title,
    );

    await workoutResult.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        }
      },
      (newWorkout) async {
        // Add all exercises from the previous workout
        for (final exercise in workout.exercises) {
          await addExerciseUseCase(
            workoutSessionId: newWorkout.id,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
          );
        }

        // Invalidate active workout provider to refresh
        ref.invalidate(activeWorkoutProvider);

        if (context.mounted) {
          // Navigate to active workout page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveWorkoutPage(workout: newWorkout),
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, bool useImperialUnits,) {
    final duration = workout.duration;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(workout.startedAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: duration != null ? _formatDuration(duration) : '--',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.fitness_center,
                  label: 'Exercises',
                  value: '${workout.exercises.length}',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.repeat,
                  label: 'Sets',
                  value: '${workout.totalSets}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.scale,
                  label: 'Volume',
                  value: UnitConversion.formatWeight(
                    workout.totalVolume,
                    useImperialUnits,
                  ),
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.straighten,
                  label: 'Total Reps',
                  value: '${workout.totalReps}',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events,
                  label: 'PRs',
                  value: '${workout.personalRecordsCount}',
                  valueColor: workout.personalRecordsCount > 0
                      ? Colors.amber[700]
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
      BuildContext context, ThemeData theme, bool useImperialUnits,) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workout.exercises.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        return _ExerciseDetailCard(
          exercise: exercise,
          useImperialUnits: useImperialUnits,
        );
      },
    );
  }

  Widget _buildNotesSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workout.notes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${DateFormat('EEEE, MMMM d, y').format(date)} at ${DateFormat.jm().format(date)}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final ExercisePerformance exercise;
  final bool useImperialUnits;

  const _ExerciseDetailCard({
    required this.exercise,
    required this.useImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxOneRM = exercise.maxOneRM;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (maxOneRM != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Est. 1RM: ${UnitConversion.formatWeight(maxOneRM, useImperialUnits)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary stats
          Row(
            children: [
              Text(
                '${exercise.workingSetsCount} working sets',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Volume: ${UnitConversion.formatWeight(exercise.totalVolume, useImperialUnits)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sets table
          _buildSetsTable(context, theme),
        ],
      ),
    );
  }

  Widget _buildSetsTable(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'Set',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    useImperialUnits ? 'Weight (lbs)' : 'Weight (kg)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Reps',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'RPE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '1RM',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Set rows
          ...exercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _SetRow(
              setNumber: index + 1,
              set: set,
              useImperialUnits: useImperialUnits,
            );
          }),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSet set;
  final bool useImperialUnits;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.useImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oneRM = set.calculated1RM;
    final weight = useImperialUnits
        ? UnitConversion.kgToLbs(set.weightKg)
        : set.weightKg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Text(
                  '$setNumber',
                  style: theme.textTheme.bodyMedium,
                ),
                if (set.isWarmup)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'W',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              weight.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${set.reps}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              set.rpe != null ? set.rpe!.toStringAsFixed(1) : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: set.rpe != null
                    ? _getRpeColor(set.rpe!, theme)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              oneRM != null && !set.isWarmup
                  ? UnitConversion.formatWeight(oneRM, useImperialUnits)
                  : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: set.isWarmup
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRpeColor(double rpe, ThemeData theme) {
    if (rpe >= 9) return Colors.red;
    if (rpe >= 8) return Colors.orange;
    if (rpe >= 7) return Colors.amber;
    return theme.colorScheme.onSurface;
  }
}
