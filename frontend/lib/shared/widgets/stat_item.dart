import 'package:flutter/material.dart';

/// A reusable stat display widget showing icon, value, and label.
class StatItem extends StatelessWidget {
  final IconData? icon;
  final String value;
  final String label;
  final Color? iconColor;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final bool compact;

  const StatItem({
    super.key,
    this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.valueColor,
    this.valueStyle,
    this.labelStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: compact ? 16 : 20,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: compact ? 2 : 4),
        ],
        Text(
          value,
          style: valueStyle ??
              (compact
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    )
                  : theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    )),
        ),
        SizedBox(height: compact ? 0 : 4),
        Text(
          label,
          style: labelStyle ??
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

/// A row of stat items.
class StatsRow extends StatelessWidget {
  final List<StatItem> stats;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const StatsRow({
    super.key,
    required this.stats,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => Expanded(child: stat)).toList(),
      ),
    );
  }
}
