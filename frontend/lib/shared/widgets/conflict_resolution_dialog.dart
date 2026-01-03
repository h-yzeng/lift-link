import 'package:flutter/material.dart';

/// Shows a dialog to resolve sync conflicts between local and remote versions
Future<T?> showConflictResolutionDialog<T>({
  required BuildContext context,
  required T localVersion,
  required T remoteVersion,
  required List<String> conflictingFields,
}) async {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Sync Conflict Detected'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The same item was modified on multiple devices. Choose which version to keep:',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conflicting fields: ${conflictingFields.join(", ")}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, localVersion),
          child: const Text('Keep This Device'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, remoteVersion),
          child: const Text('Use Cloud Version'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel Sync'),
        ),
      ],
    ),
  );
}
