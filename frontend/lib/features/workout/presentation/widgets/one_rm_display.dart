import 'package:flutter/material.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';

/// Widget to display the calculated 1RM using the Epley formula
class OneRMDisplay extends StatelessWidget {
  final double? oneRM;
  final bool isWarmup;
  final bool useImperialUnits;

  const OneRMDisplay({
    required this.oneRM,
    this.isWarmup = false,
    this.useImperialUnits = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isWarmup) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'WARMUP',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    if (oneRM == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'N/A',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Est. 1RM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            UnitConversion.formatWeight(oneRM!, useImperialUnits),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
