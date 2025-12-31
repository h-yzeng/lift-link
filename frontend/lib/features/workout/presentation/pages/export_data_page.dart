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
  ExportFormat _selectedFormat = ExportFormat.json;
  bool _isExporting = false;
  String? _exportedData;
  String? _error;

  Future<void> _exportData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() {
      _isExporting = true;
      _error = null;
      _exportedData = null;
    });

    try {
      final useCase = ref.read(exportWorkoutDataUseCaseProvider);
      final result = await useCase(
        userId: user.id,
        format: _selectedFormat,
      );

      result.fold(
        (failure) {
          setState(() {
            _error = failure.userMessage;
          });
        },
        (data) {
          setState(() {
            _exportedData = data;
          });
        },
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_exportedData == null) return;

    await Clipboard.setData(ClipboardData(text: _exportedData!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    }
  }

  Future<void> _shareData() async {
    if (_exportedData == null) return;

    try {
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final extension = _selectedFormat == ExportFormat.json ? 'json' : 'csv';
      final fileName = 'liftlink_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(_exportedData!);

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
    if (_exportedData == null) return;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final extension = _selectedFormat == ExportFormat.json ? 'json' : 'csv';
      final fileName = 'liftlink_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsString(_exportedData!);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    isSelected: _selectedFormat == ExportFormat.json,
                    onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatOption(
                    title: 'CSV',
                    subtitle: 'Spreadsheet compatible',
                    icon: Icons.table_chart,
                    isSelected: _selectedFormat == ExportFormat.csv,
                    onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Generate Export'),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_exportedData != null) ...[
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _exportedData!.length > 5000
                          ? '${_exportedData!.substring(0, 5000)}\n\n... (truncated for preview)'
                          : _exportedData!,
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
                'Size: ${(_exportedData!.length / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
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
