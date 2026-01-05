import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/bodyweight/domain/entities/weight_log.dart';
import 'package:liftlink/features/bodyweight/presentation/providers/weight_log_providers.dart';
import 'package:liftlink/shared/widgets/widgets.dart';

class WeightLogPage extends ConsumerStatefulWidget {
  const WeightLogPage({super.key});

  @override
  ConsumerState<WeightLogPage> createState() => _WeightLogPageState();
}

class _WeightLogPageState extends ConsumerState<WeightLogPage> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedUnit = 'kg';

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _logWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight')),
        );
      }
      return;
    }

    await ref
        .read(weightLogProvider.notifier)
        .logWeight(
          weight: weight,
          unit: _selectedUnit,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (mounted) {
      _weightController.clear();
      _notesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight logged successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightLogsAsync = ref.watch(weightLogsProvider());
    final latestWeightAsync = ref.watch(latestWeightLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Body Weight')),
      body: Column(
        children: [
          // Latest weight display
          latestWeightAsync.when(
            data: (latest) {
              if (latest == null) {
                return const SizedBox.shrink();
              }
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weight',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        latest.formattedWeight,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (latest.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          latest.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Log weight form
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Weight',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ValidatedTextField(
                          controller: _weightController,
                          labelText: 'Weight',
                          validationType: ValidationType.decimal,
                          minValue: 0.1,
                          maxValue: 999.9,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedUnit,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ValidatedTextField(
                    controller: _notesController,
                    labelText: 'Notes (optional)',
                    hintText: 'Add any notes about this measurement',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _logWeight,
                      child: const Text('Log Weight'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Weight history list
          Expanded(
            child: weightLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.monitor_weight_outlined,
                    title: 'No Weight Logs',
                    subtitle: 'Start tracking your weight above',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    WeightLog? previousLog;
                    if (index < logs.length - 1) {
                      previousLog = logs[index + 1];
                    }

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.monitor_weight),
                        title: Text(log.formattedWeight),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(log.loggedAt)),
                            if (previousLog != null) ...[
                              const SizedBox(height: 4),
                              _buildWeightChange(log, previousLog),
                            ],
                            if (log.notes != null) ...[
                              const SizedBox(height: 4),
                              Text(log.notes!),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(log.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(weightLogsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChange(WeightLog current, WeightLog previous) {
    final change = current.weightChangeTo(previous);
    final isGain = change > 0;
    final color = isGain ? Colors.red : Colors.green;
    final icon = isGain ? Icons.arrow_upward : Icons.arrow_downward;
    final text = '${change.abs().toStringAsFixed(1)} ${current.unit}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Weight Log'),
        content: const Text('Are you sure you want to delete this weight log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(weightLogProvider.notifier).deleteWeight(id);
    }
  }
}
