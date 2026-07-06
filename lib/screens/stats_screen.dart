import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  String _formatBytes(int b) {
    if (b <= 0) return '0 B';
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double value = b.toDouble();
    int unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  @override
  Widget build(BuildContext context) {
    final StorageService storage = context.watch<StorageService>();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _tile(
            context,
            icon: Icons.photo_library_rounded,
            label: 'Files backed up',
            value: storage.uploadedCount.toString(),
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.cloud_done_rounded,
            label: 'Total data uploaded',
            value: _formatBytes(storage.uploadedBytes),
            color: cs.tertiary,
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.timelapse_rounded,
            label: 'Unique assets tracked',
            value: storage.uploadedIds.length.toString(),
            color: cs.secondary,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Reset statistics?'),
                  content: const Text(
                      'This clears local counters. It does NOT delete anything from Telegram.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await storage.reset();
              }
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset local statistics'),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurfaceVariant,
                        )),
                const SizedBox(height: 4),
                Text(value,
                    style: Theme.of(ctx)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
