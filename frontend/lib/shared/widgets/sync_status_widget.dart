import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/sync/sync_provider.dart';
import 'package:liftlink/core/sync/sync_service.dart';

/// A widget that displays the current sync status and allows manual sync.
class SyncStatusWidget extends ConsumerWidget {
  final bool showLabel;

  const SyncStatusWidget({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);

    return syncStatusAsync.when(
      data: (status) => _buildStatusIndicator(context, ref, status),
      loading: () => _buildStatusIndicator(context, ref, SyncResult.idle()),
      error: (_, _) => _buildStatusIndicator(
        context,
        ref,
        SyncResult.error('Unknown error'),
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    WidgetRef ref,
    SyncResult result,
  ) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String tooltip;

    switch (result.status) {
      case SyncStatus.idle:
        icon = Icons.cloud_done;
        color = theme.colorScheme.outline;
        tooltip = 'Tap to sync';
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        tooltip = 'Syncing...';
      case SyncStatus.success:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'Synced';
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = theme.colorScheme.error;
        tooltip = result.message ?? 'Sync failed';
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = theme.colorScheme.outline;
        tooltip = 'Offline';
    }

    return IconButton(
      icon: result.status == SyncStatus.syncing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, color: color),
      onPressed: result.status == SyncStatus.syncing
          ? null
          : () => _triggerSync(context, ref),
      tooltip: tooltip,
    );
  }

  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(syncServiceProvider);
    final result = await syncService.syncAll();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getStatusMessage(result)),
        duration: const Duration(seconds: 2),
        backgroundColor: _getStatusColor(result, Theme.of(context)),
      ),
    );
  }

  String _getStatusMessage(SyncResult result) {
    switch (result.status) {
      case SyncStatus.success:
        return 'Sync complete';
      case SyncStatus.error:
        return 'Sync failed: ${result.message}';
      case SyncStatus.offline:
        return 'No internet connection';
      default:
        return 'Syncing...';
    }
  }

  Color _getStatusColor(SyncResult result, ThemeData theme) {
    switch (result.status) {
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.offline:
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.primary;
    }
  }
}

/// A card widget showing detailed sync status for the settings page.
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Data Sync',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            syncStatusAsync.when(
              data: (status) => _buildStatusDetails(context, ref, status),
              loading: () =>
                  _buildStatusDetails(context, ref, SyncResult.idle()),
              error: (_, _) => _buildStatusDetails(
                context,
                ref,
                SyncResult.error('Unknown error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDetails(
    BuildContext context,
    WidgetRef ref,
    SyncResult result,
  ) {
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (result.status) {
      case SyncStatus.idle:
        statusText = 'Ready to sync';
        statusColor = theme.colorScheme.outline;
        statusIcon = Icons.cloud_queue;
      case SyncStatus.syncing:
        statusText = 'Syncing...';
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.sync;
      case SyncStatus.success:
        statusText = 'Last sync: ${_formatTime(result.timestamp)}';
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
      case SyncStatus.error:
        statusText = result.message ?? 'Sync failed';
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.error_outline;
      case SyncStatus.offline:
        statusText = 'No internet connection';
        statusColor = theme.colorScheme.outline;
        statusIcon = Icons.cloud_off;
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: result.status == SyncStatus.syncing
                ? null
                : () => _triggerSync(context, ref),
            icon: result.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(
              result.status == SyncStatus.syncing ? 'Syncing...' : 'Sync Now',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.syncAll();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
