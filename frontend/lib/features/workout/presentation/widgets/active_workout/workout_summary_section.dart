import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/core/preferences/workout_duration_preference.dart';
import 'package:liftlink/core/preferences/rest_timer_preference.dart';

/// Displays workout statistics summary at the top of active workout page
class WorkoutSummarySection extends ConsumerWidget {
  final WorkoutSession workout;
  final bool useImperialUnits;

  const WorkoutSummarySection({
    required this.workout,
    required this.useImperialUnits,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final targetDuration = ref.watch(targetWorkoutDurationProvider);
    final currentDuration = workout.actualDuration;
    final progress = (currentDuration / targetDuration).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Duration progress bar
          if (targetDuration > 0)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${WorkoutDurationPresets.formatDuration(targetDuration)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Estimated completion time
                if (workout.isInProgress) ...[
                  _EstimatedCompletion(workout: workout, ref: ref),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: workout.formattedDuration,
              ),
              _StatItem(
                icon: Icons.fitness_center,
                label: 'Exercises',
                value: '${workout.exercises.length}',
              ),
              _StatItem(
                icon: Icons.repeat,
                label: 'Sets',
                value: '${workout.totalSets}',
              ),
              _StatItem(
                icon: Icons.scale,
                label: 'Volume',
                value: UnitConversion.formatWeight(
                  workout.totalVolume,
                  useImperialUnits,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual stat display item
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      readOnly: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estimated workout completion time
class _EstimatedCompletion extends StatelessWidget {
  final WorkoutSession workout;
  final WidgetRef ref;

  const _EstimatedCompletion({
    required this.workout,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate remaining sets
    final totalSets = workout.totalSets;
    final completedSets = workout.exercises
        .expand((e) => e.sets)
        .where((s) => s.reps > 0 && s.weightKg > 0)
        .length;
    final remainingSets = totalSets - completedSets;

    if (remainingSets <= 0) return const SizedBox.shrink();

    // Get average rest time
    final defaultRestSeconds = ref.read(defaultRestTimerSecondsProvider);

    // Estimate: remaining sets * (30s work + rest time)
    final workTimePerSet = 30; // seconds
    final estimatedSeconds =
        remainingSets * (workTimePerSet + defaultRestSeconds);
    final estimatedMinutes = (estimatedSeconds / 60).ceil();

    // Calculate estimated completion time
    final now = DateTime.now();
    final estimatedCompletion = now.add(Duration(seconds: estimatedSeconds));
    final timeString =
        '${estimatedCompletion.hour.toString().padLeft(2, '0')}:${estimatedCompletion.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Est. completion: ~$timeString ($estimatedMinutes min)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
