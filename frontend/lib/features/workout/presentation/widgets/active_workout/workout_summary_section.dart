import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
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
