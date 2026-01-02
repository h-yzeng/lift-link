import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

/// Widget for inputting set data (weight, reps, RPE)
class SetInputRow extends StatefulWidget {
  final WorkoutSet? existingSet;
  final int setNumber;
  final bool useImperialUnits;
  final Function(int reps, double weight, bool isWarmup, double? rpe, int? rir)? onSave;
  final VoidCallback? onDelete;

  const SetInputRow({
    required this.setNumber,
    this.existingSet,
    this.useImperialUnits = false,
    this.onSave,
    this.onDelete,
    super.key,
  });

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _rpeController;
  late TextEditingController _rirController;
  late bool _isWarmup;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isWarmup = widget.existingSet?.isWarmup ?? false;

    // Convert weight to display unit
    final displayWeight = widget.existingSet != null
        ? UnitConversion.formatWeightValue(
            widget.existingSet!.weightKg,
            widget.useImperialUnits,
          )
        : '';

    _weightController = TextEditingController(text: displayWeight);
    _repsController = TextEditingController(
      text: widget.existingSet?.reps.toString() ?? '',
    );
    _rpeController = TextEditingController(
      text: widget.existingSet?.rpe?.toString() ?? '',
    );
    _rirController = TextEditingController(
      text: widget.existingSet?.rir?.toString() ?? '',
    );

    // Start in edit mode if:
    // 1. This is a new set (existingSet is null), OR
    // 2. This is a freshly added set with no data (reps = 0 and weight = 0)
    _isEditing = widget.existingSet == null ||
        (widget.existingSet!.reps == 0 && widget.existingSet!.weightKg == 0.0);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  void _saveSet() {
    final inputWeight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final rpe = _rpeController.text.isNotEmpty
        ? double.tryParse(_rpeController.text)
        : null;
    final rir = _rirController.text.isNotEmpty
        ? int.tryParse(_rirController.text)
        : null;

    if (inputWeight != null && reps != null) {
      // Convert weight to kg if imperial units are used
      final weightKg = widget.useImperialUnits
          ? UnitConversion.lbsToKg(inputWeight)
          : inputWeight;

      widget.onSave?.call(reps, weightKg, _isWarmup, rpe, rir);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oneRM = widget.existingSet?.calculated1RM;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: _isEditing ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with set number and action buttons
            Row(
              children: [
                // Set number badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.setNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _isEditing
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Set type indicators
                if (_isWarmup)
                  Chip(
                    label: const Text('Warmup'),
                    avatar: const Icon(Icons.local_fire_department, size: 16),
                    labelStyle: theme.textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),

                const Spacer(),

                // 1RM display (compact)
                if (oneRM != null && !_isWarmup)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          UnitConversion.formatWeight(
                            oneRM,
                            widget.useImperialUnits,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),

                // Action buttons
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: _saveSet,
                    color: theme.colorScheme.primary,
                    iconSize: 28,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    iconSize: 24,
                  ),

                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                    color: theme.colorScheme.error,
                    iconSize: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Input fields row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight input with label underneath
                Expanded(
                  flex: 3,
                  child: _InputFieldWithLabel(
                    controller: _weightController,
                    enabled: _isEditing,
                    label: 'Weight (${UnitConversion.getWeightUnit(widget.useImperialUnits)})',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Reps input with label underneath
                Expanded(
                  flex: 2,
                  child: _InputFieldWithLabel(
                    controller: _repsController,
                    enabled: _isEditing,
                    label: 'Reps',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),

                // RPE input with label underneath
                Expanded(
                  flex: 2,
                  child: _InputFieldWithLabel(
                    controller: _rpeController,
                    enabled: _isEditing,
                    label: 'RPE',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{1,2}\.?\d?')),
                    ],
                    isOptional: true,
                  ),
                ),
                const SizedBox(width: 12),

                // RIR input with label underneath
                Expanded(
                  flex: 2,
                  child: _InputFieldWithLabel(
                    controller: _rirController,
                    enabled: _isEditing,
                    label: 'RIR',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{1,2}')),
                    ],
                    isOptional: true,
                  ),
                ),
              ],
            ),

            // Warmup toggle
            if (_isEditing) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _isWarmup = !_isWarmup;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isWarmup,
                        onChanged: (value) {
                          setState(() {
                            _isWarmup = value ?? false;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Warmup Set',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom widget for input field with label underneath
class _InputFieldWithLabel extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isOptional;

  const _InputFieldWithLabel({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.keyboardType,
    this.inputFormatters,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input field
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            hintText: isOptional ? '—' : '0',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Label underneath
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
