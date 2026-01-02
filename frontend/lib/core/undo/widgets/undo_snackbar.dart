import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/undo/undo_action.dart';
import 'package:liftlink/core/undo/undo_provider.dart';

/// Shows a snackbar with an undo option
void showUndoSnackbar(
  BuildContext context,
  WidgetRef ref, {
  required UndoAction action,
  required Future<void> Function() onUndo,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(action.description),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          try {
            await onUndo();
            final undoService = await ref.read(undoServiceProvider.future);
            await undoService.removeAction(action.id);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action undone'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to undo: ${e.toString()}'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    ),
  );
}
