import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/presentation/widgets/one_rm_display.dart';

/// Widget for inputting set data (weight, reps, RPE)
class SetInputRow extends StatefulWidget {
  final WorkoutSet? existingSet;
  final int setNumber;
  final Function(int reps, double weight, bool isWarmup, double? rpe)? onSave;
  final VoidCallback? onDelete;

  const SetInputRow({
    required this.setNumber,
    this.existingSet,
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
  late bool _isWarmup;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isWarmup = widget.existingSet?.isWarmup ?? false;
    _weightController = TextEditingController(
      text: widget.existingSet?.weightKg.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.existingSet?.reps.toString() ?? '',
    );
    _rpeController = TextEditingController(
      text: widget.existingSet?.rpe?.toString() ?? '',
    );
    _isEditing = widget.existingSet == null;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _saveSet() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final rpe = _rpeController.text.isNotEmpty
        ? double.tryParse(_rpeController.text)
        : null;

    if (weight != null && reps != null) {
      widget.onSave?.call(reps, weight, _isWarmup, rpe);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oneRM = widget.existingSet?.calculated1RM;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Set number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.setNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Weight input
            Expanded(
              child: TextField(
                controller: _weightController,
                enabled: _isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Reps input
            Expanded(
              child: TextField(
                controller: _repsController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // RPE input (optional)
            SizedBox(
              width: 60,
              child: TextField(
                controller: _rpeController,
                enabled: _isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{1,2}\.?\d?')),
                ],
                decoration: const InputDecoration(
                  labelText: 'RPE',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Warmup checkbox
            Checkbox(
              value: _isWarmup,
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _isWarmup = value ?? false;
                      });
                    }
                  : null,
            ),
            const SizedBox(width: 8),

            // 1RM display
            OneRMDisplay(
              oneRM: oneRM,
              isWarmup: _isWarmup,
            ),
            const SizedBox(width: 8),

            // Action buttons
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveSet,
                color: Theme.of(context).colorScheme.primary,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),

            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: widget.onDelete,
                color: Theme.of(context).colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }
}
