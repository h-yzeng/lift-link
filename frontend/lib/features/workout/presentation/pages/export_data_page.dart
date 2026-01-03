import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/usecases/export_workout_data.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Provider for the export use case.
final exportWorkoutDataUseCaseProvider = Provider<ExportWorkoutData>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return ExportWorkoutData(repository);
});

/// Page for exporting workout data.
class ExportDataPage extends ConsumerStatefulWidget {
  const ExportDataPage({super.key});

  @override
  ConsumerState<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends ConsumerState<ExportDataPage> {
  // Using ValueNotifiers to eliminate setState calls
  final _selectedFormatNotifier = ValueNotifier(ExportFormat.json);
  final _isExportingNotifier = ValueNotifier(false);
  final _exportedDataNotifier = ValueNotifier<String?>(null);
  final _errorNotifier = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _selectedFormatNotifier.dispose();
    _isExportingNotifier.dispose();
    _exportedDataNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    _isExportingNotifier.value = true;
    _errorNotifier.value = null;
    _exportedDataNotifier.value = null;

    try {
      final useCase = ref.read(exportWorkoutDataUseCaseProvider);
      final result = await useCase(
        userId: user.id,
        format: _selectedFormatNotifier.value,
      );

      result.fold(
        (failure) {
          _errorNotifier.value = failure.userMessage;
        },
        (data) {
          _exportedDataNotifier.value = data;
        },
      );
    } finally {
      _isExportingNotifier.value = false;
    }
  }

  Future<void> _copyToClipboard() async {
    final data = _exportedDataNotifier.value;
    if (data == null) return;

    await Clipboard.setData(ClipboardData(text: data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    }
  }

  Future<void> _shareData() async {
    final data = _exportedDataNotifier.value;
    if (data == null) return;

    try {
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final extension =
          _selectedFormatNotifier.value == ExportFormat.json ? 'json' : 'csv';
      final fileName =
          'liftlink_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(data);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LiftLink Workout Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveToFile() async {
    final data = _exportedDataNotifier.value;
    if (data == null) return;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final extension =
          _selectedFormatNotifier.value == ExportFormat.json ? 'json' : 'csv';
      final fileName =
          'liftlink_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsString(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: ValueListenableBuilder<ExportFormat>(
        valueListenable: _selectedFormatNotifier,
        builder: (context, selectedFormat, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isExportingNotifier,
            builder: (context, isExporting, _) {
              return ValueListenableBuilder<String?>(
                valueListenable: _errorNotifier,
                builder: (context, error, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _exportedDataNotifier,
                    builder: (context, exportedData, _) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Format selection
                            Text(
                              'Export Format',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormatOption(
                                    title: 'JSON',
                                    subtitle: 'Full structured data',
                                    icon: Icons.code,
                                    isSelected:
                                        selectedFormat == ExportFormat.json,
                                    onTap: () => _selectedFormatNotifier.value =
                                        ExportFormat.json,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _FormatOption(
                                    title: 'CSV',
                                    subtitle: 'Spreadsheet compatible',
                                    icon: Icons.table_chart,
                                    isSelected:
                                        selectedFormat == ExportFormat.csv,
                                    onTap: () => _selectedFormatNotifier.value =
                                        ExportFormat.csv,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Export button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isExporting ? null : _exportData,
                                icon: isExporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: Text(
                                  isExporting
                                      ? 'Exporting...'
                                      : 'Generate Export',
                                ),
                              ),
                            ),

                            if (error != null) ...[
                              const SizedBox(height: 16),
                              Card(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            if (exportedData != null) ...[
                              const SizedBox(height: 24),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _copyToClipboard,
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _shareData,
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _saveToFile,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Preview
                              Text(
                                'Preview',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: SelectableText(
                                      exportedData.length > 5000
                                          ? '${exportedData.substring(0, 5000)}\n\n... (truncated for preview)'
                                          : exportedData,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Size: ${(exportedData.length / 1024).toStringAsFixed(1)} KB',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
