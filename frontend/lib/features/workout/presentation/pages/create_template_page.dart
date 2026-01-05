import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
import 'package:liftlink/features/workout/presentation/providers/create_template_notifier.dart';
import 'package:liftlink/features/workout/presentation/providers/template_providers.dart';

/// Page for creating a new workout template.
class CreateTemplatePage extends ConsumerStatefulWidget {
  const CreateTemplatePage({super.key});

  @override
  ConsumerState<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends ConsumerState<CreateTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final exercise = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseListPage(selectionMode: true),
      ),
    );

    if (exercise == null || !mounted) return;

    // Show dialog to set default sets
    final sets = await showDialog<int>(
      context: context,
      builder: (context) => _SetCountDialog(exerciseName: exercise['name']!),
    );

    if (sets == null) return;

    ref.read(createTemplateProvider.notifier).addExercise(
          TemplateExercise(
            exerciseId: exercise['id']!,
            exerciseName: exercise['name']!,
            sets: sets,
          ),
        );
  }

  void _removeExercise(int index) {
    ref.read(createTemplateProvider.notifier).removeExercise(index);
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    ref
        .read(createTemplateProvider.notifier)
        .reorderExercises(oldIndex, newIndex);
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final templateState = ref.read(createTemplateProvider);
    if (!templateState.hasExercises) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final notifier = ref.read(createTemplateProvider.notifier);
    notifier.setSaving(true);

    try {
      final useCase = ref.read(createTemplateUseCaseProvider);
      final result = await useCase(
        userId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        exercises: templateState.exercises,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.userMessage)),
            );
          }
        },
        (_) {
          ref.invalidate(templatesProvider);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Template created!')),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        notifier.setSaving(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(createTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Template'),
        actions: [
          if (templateState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveTemplate,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Template name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Push Day, Leg Day',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a template name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this workout',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Exercises section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!templateState.hasExercises)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No exercises added',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templateState.exercises.length,
                onReorder: _reorderExercises,
                itemBuilder: (context, index) {
                  final exercise = templateState.exercises[index];
                  return Card(
                    key: ValueKey(exercise.exerciseId + index.toString()),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(exercise.exerciseName),
                      subtitle: Text('${exercise.sets} sets'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeExercise(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SetCountDialog extends StatefulWidget {
  final String exerciseName;

  const _SetCountDialog({required this.exerciseName});

  @override
  State<_SetCountDialog> createState() => _SetCountDialogState();
}

class _SetCountDialogState extends State<_SetCountDialog> {
  final ValueNotifier<int> _setsNotifier = ValueNotifier(3);

  @override
  void dispose() {
    _setsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.exerciseName}'),
      content: ValueListenableBuilder<int>(
        valueListenable: _setsNotifier,
        builder: (context, sets, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How many sets?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        sets > 1 ? () => _setsNotifier.value = sets - 1 : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$sets',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        sets < 10 ? () => _setsNotifier.value = sets + 1 : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _setsNotifier.value),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
