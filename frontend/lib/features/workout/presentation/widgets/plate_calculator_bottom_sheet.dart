import 'package:flutter/material.dart';
import 'package:liftlink/core/utils/plate_calculator.dart';

/// Bottom sheet that shows plate loading calculation
class PlateCalculatorBottomSheet extends StatelessWidget {
  final double targetWeight;
  final bool useImperial;

  const PlateCalculatorBottomSheet({
    required this.targetWeight,
    required this.useImperial,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plates = PlateCalculator.calculatePlates(
      targetWeight: targetWeight,
      useImperial: useImperial,
    );
    final actualWeight = PlateCalculator.getActualWeight(
      targetWeight: targetWeight,
      useImperial: useImperial,
    );
    final unit = useImperial ? 'lb' : 'kg';
    final barbell = useImperial
        ? PlateCalculator.standardBarbellLbs
        : PlateCalculator.standardBarbellKg;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Plate Calculator',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target weight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${targetWeight.toStringAsFixed(1)} $unit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Barbell
          ListTile(
            leading: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.secondary,
            ),
            title: const Text('Barbell'),
            trailing: Text(
              '${barbell.toStringAsFixed(0)} $unit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),

          if (plates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                targetWeight <= barbell
                    ? 'Use empty bar only'
                    : 'Cannot load exactly with standard plates',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Load each side with:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Plates list
            ...plates.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPlateColor(entry.key, useImperial),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.value}×',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${entry.key.toStringAsFixed(entry.key % 1 == 0 ? 0 : 1)} $unit plate',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }),

            if (actualWeight != targetWeight) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Actual: ${actualWeight.toStringAsFixed(1)} $unit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Get color for plate based on weight (standard gym plate colors)
  Color _getPlateColor(double weight, bool useImperial) {
    if (useImperial) {
      if (weight >= 45) return Colors.red;
      if (weight >= 35) return Colors.yellow;
      if (weight >= 25) return Colors.green;
      if (weight >= 10) return Colors.blue;
      return Colors.grey;
    } else {
      if (weight >= 25) return Colors.red;
      if (weight >= 20) return Colors.blue;
      if (weight >= 15) return Colors.yellow;
      if (weight >= 10) return Colors.green;
      return Colors.grey;
    }
  }
}

/// Show plate calculator bottom sheet
void showPlateCalculator(
  BuildContext context, {
  required double targetWeight,
  required bool useImperial,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => PlateCalculatorBottomSheet(
      targetWeight: targetWeight,
      useImperial: useImperial,
    ),
  );
}
