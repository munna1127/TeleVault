import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';

/// A bottom sheet that displays real-time upload progress.
class ProgressDialog extends StatelessWidget {
  const ProgressDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BackupService>(),
        child: const ProgressDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<BackupService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = backup.backupState == BackupState.done ||
        backup.backupState == BackupState.error ||
        backup.backupState == BackupState.idle;

    final progress = backup.uploadTotal > 0
        ? backup.uploadCurrent / backup.uploadTotal
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Icon(
                isDone
                    ? (backup.backupState == BackupState.error
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded)
                    : Icons.cloud_upload_outlined,
                color: isDone
                    ? (backup.backupState == BackupState.error
                        ? colorScheme.error
                        : colorScheme.primary)
                    : colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isDone ? 'Backup Complete' : 'Backing Up…',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress bar
          if (!isDone) ...[
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress != null
                      ? '${backup.uploadCurrent} / ${backup.uploadTotal} files'
                      : 'Preparing…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Status message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              backup.uploadStatusMessage.isEmpty
                  ? 'Starting…'
                  : backup.uploadStatusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Success summary
          if (isDone && backup.backupState == BackupState.done) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _SummaryChip(
                  label: '${backup.lastSuccessCount} uploaded',
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 8),
                if (backup.lastFailCount > 0)
                  _SummaryChip(
                    label: '${backup.lastFailCount} skipped',
                    color: Colors.orange,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: isDone
                ? FilledButton(
                    onPressed: () {
                      backup.resetToIdle();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  )
                : OutlinedButton(
                    onPressed: () {
                      backup.cancelBackup();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
