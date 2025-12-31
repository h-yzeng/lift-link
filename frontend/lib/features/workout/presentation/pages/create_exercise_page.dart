import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:liftlink/shared/utils/result_extensions.dart';

/// Page for creating a custom exercise.
class CreateExercisePage extends ConsumerStatefulWidget {
  const CreateExercisePage({super.key});

  @override
  ConsumerState<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends ConsumerState<CreateExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedMuscleGroup = MuscleGroups.chest;
  String? _selectedEquipment;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createExercise() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(exerciseRepositoryProvider);
      final result = await repository.createCustomExercise(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        muscleGroup: _selectedMuscleGroup,
        equipmentType: _selectedEquipment,
        userId: user.id,
      );

      if (!mounted) return;

      result.handleResult(
        context,
        onSuccess: (exercise) {
          ref.invalidate(exerciseListProvider);
          context.showSuccessSnackBar('Exercise "${exercise.name}" created!');
          Navigator.pop(context, exercise);
        },
        failurePrefix: 'Failed to create exercise',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Incline Dumbbell Press',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the exercise',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Muscle group selection
            Text(
              'Muscle Group',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroups.all.map((muscle) {
                final isSelected = _selectedMuscleGroup == muscle;
                return FilterChip(
                  label: Text(_formatLabel(muscle)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedMuscleGroup = muscle);
                  },
                  avatar: Icon(
                    _getMuscleGroupIcon(muscle),
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Equipment selection
            Text(
              'Equipment (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Any'),
                  selected: _selectedEquipment == null,
                  onSelected: (selected) {
                    setState(() => _selectedEquipment = null);
                  },
                ),
                ...EquipmentTypes.all.map((equipment) {
                  final isSelected = _selectedEquipment == equipment;
                  return FilterChip(
                    label: Text(_formatLabel(equipment)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedEquipment = selected ? equipment : null;
                      });
                    },
                    avatar: Icon(
                      _getEquipmentIcon(equipment),
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 32),

            // Preview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Preview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Exercise Name'
                          : _nameController.text,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(_formatLabel(_selectedMuscleGroup)),
                          avatar: Icon(
                            _getMuscleGroupIcon(_selectedMuscleGroup),
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            _selectedEquipment != null
                                ? _formatLabel(_selectedEquipment!)
                                : 'Any Equipment',
                          ),
                          avatar: Icon(
                            _selectedEquipment != null
                                ? _getEquipmentIcon(_selectedEquipment!)
                                : Icons.fitness_center,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (_descriptionController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _descriptionController.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Custom Exercise',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create button
            FilledButton.icon(
              onPressed: _isLoading ? null : _createExercise,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Creating...' : 'Create Exercise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup) {
      case MuscleGroups.chest:
        return Icons.fitness_center;
      case MuscleGroups.back:
        return Icons.airline_seat_flat;
      case MuscleGroups.legs:
        return Icons.directions_walk;
      case MuscleGroups.shoulders:
        return Icons.accessibility_new;
      case MuscleGroups.arms:
        return Icons.sports_martial_arts;
      case MuscleGroups.core:
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case EquipmentTypes.barbell:
        return Icons.fitness_center;
      case EquipmentTypes.dumbbell:
        return Icons.fitness_center;
      case EquipmentTypes.machine:
        return Icons.precision_manufacturing;
      case EquipmentTypes.cable:
        return Icons.cable;
      case EquipmentTypes.bodyweight:
        return Icons.person;
      default:
        return Icons.fitness_center;
    }
  }
}
