import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/telegram_service.dart';

class UploadProgressCard extends StatelessWidget {
  const UploadProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final TelegramService svc = context.watch<TelegramService>();
    if (svc.queue.isEmpty) return const SizedBox.shrink();

    final ColorScheme cs = Theme.of(context).colorScheme;
    final int total = svc.queue.length;
    final int done = svc.completedCount;
    final int failed = svc.failedCount;
    final int skipped = svc.skippedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.sync_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  svc.isRunning
                      ? 'Uploading $done of $total…'
                      : 'Finished: $done ok • $failed failed • $skipped skipped',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (svc.isRunning)
                TextButton(
                  onPressed: svc.cancel,
                  child: const Text('Stop'),
                )
              else
                TextButton(
                  onPressed: svc.clear,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: svc.overallProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          ...svc.queue.take(4).map((UploadItem item) => _row(context, item)),
          if (svc.queue.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('+ ${svc.queue.length - 4} more',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext ctx, UploadItem item) {
    final ColorScheme cs = Theme.of(ctx).colorScheme;
    final Widget trailing = switch (item.phase) {
      UploadPhase.done =>
        Icon(Icons.check_circle_rounded, color: cs.tertiary, size: 20),
      UploadPhase.error =>
        Icon(Icons.error_rounded, color: cs.error, size: 20),
      UploadPhase.skipped =>
        Icon(Icons.remove_circle_outline, color: cs.outline, size: 20),
      UploadPhase.uploading => SizedBox(
          width: 40,
          child: Text('${(item.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: cs.primary, fontSize: 12)),
        ),
      UploadPhase.pending => Text('…',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(ctx).textTheme.bodyMedium),
                if (item.errorMessage != null)
                  Text(item.errorMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.error)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
