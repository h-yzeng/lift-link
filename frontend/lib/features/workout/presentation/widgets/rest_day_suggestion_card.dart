import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/workout/domain/services/rest_day_suggestion_service.dart';
import 'package:liftlink/features/workout/presentation/providers/rest_day_provider.dart';

/// Widget displaying rest day suggestions based on recent workout patterns.
///
/// Shows a card with personalized recommendations for rest days,
/// helping users optimize recovery and prevent overtraining.
class RestDaySuggestionCard extends ConsumerWidget {
  const RestDaySuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(restDaySuggestionProvider);

    return suggestionAsync.when(
      data: (suggestion) => _buildSuggestionCard(context, suggestion),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    RestDaySuggestion suggestion,
  ) {
    // Determine card styling based on suggestion
    final shouldRest = suggestion.shouldRest;
    final theme = Theme.of(context);

    final backgroundColor = shouldRest
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.primaryContainer;

    final textColor = shouldRest
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onPrimaryContainer;

    final icon = shouldRest ? Icons.spa : Icons.fitness_center;
    final iconColor = shouldRest
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    // Confidence indicator
    final confidenceText = _getConfidenceText(suggestion.confidenceLevel);

    return Card(
      color: backgroundColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shouldRest ? 'Rest Day Recommended' : 'Ready to Train',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    confidenceText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reason
            Text(
              suggestion.reason,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),

            // Days until rest (if not resting today)
            if (!shouldRest && suggestion.daysUntilRecommendedRest > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Consider rest in ${suggestion.daysUntilRecommendedRest} day${suggestion.daysUntilRecommendedRest > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getConfidenceText(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }
}
