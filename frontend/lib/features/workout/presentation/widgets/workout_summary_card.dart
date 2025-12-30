import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

/// Card widget displaying a summary of a completed workout
class WorkoutSummaryCard extends StatelessWidget {
  final WorkoutSession workout;
  final bool useImperialUnits;
  final VoidCallback? onTap;

  const WorkoutSummaryCard({
    required this.workout,
    this.useImperialUnits = true,
    this.onTap,
    super.key,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today at ${DateFormat.jm().format(date)}';
    } else if (workoutDate == yesterday) {
      return 'Yesterday at ${DateFormat.jm().format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = workout.duration;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      workout.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(workout.startedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: duration != null ? _formatDuration(duration) : '--',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.fitness_center,
                    label: '${workout.exercises.length} exercises',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.repeat,
                    label: '${workout.totalSets} sets',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Volume and exercise list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Exercise names
                  Expanded(
                    child: Text(
                      workout.exercises.map((e) => e.exerciseName).join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Total volume
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
                      UnitConversion.formatWeight(
                        workout.totalVolume,
                        useImperialUnits,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Personal records indicator
              if (workout.personalRecordsCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.personalRecordsCount} PR${workout.personalRecordsCount > 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
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
