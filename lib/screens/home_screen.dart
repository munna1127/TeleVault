import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../services/telegram_service.dart';
import '../widgets/upload_progress_card.dart';
import 'gallery_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PermissionService _permissions = const PermissionService();
  bool _requesting = false;

  Future<void> _openGallery() async {
    setState(() => _requesting = true);
    final PermissionOutcome outcome = await _permissions.ensureGalleryAccess();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (!outcome.granted) {
      _showPermissionDialog(permanentlyDenied: outcome.permanentlyDenied);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GalleryScreen(),
      ),
    );
  }

  void _showPermissionDialog({required bool permanentlyDenied}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Gallery permission required'),
        content: Text(permanentlyDenied
            ? 'Photos & videos access is permanently denied. Open the system settings to enable it.'
            : 'TeleVault needs to read your photos and videos so it can upload them to your Telegram chat.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (permanentlyDenied) {
                await _permissions.openSettings();
              } else {
                await _openGallery();
              }
            },
            child: Text(permanentlyDenied ? 'Open settings' : 'Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final StorageService storage = context.watch<StorageService>();
    final TelegramService telegram = context.watch<TelegramService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StatsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          _HeroCard(
            uploaded: storage.uploadedCount,
            bytes: storage.uploadedBytes,
          ),
          const SizedBox(height: 20),
          if (!AppConstants.isConfigured)
            Card(
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded,
                        color: cs.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bot token or chat ID missing. Edit lib/constants.dart before uploading.',
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!AppConstants.isConfigured) const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _requesting ? null : _openGallery,
            icon: _requesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_library_rounded),
            label: const Text('Browse gallery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StatsScreen(),
              ),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('View statistics'),
          ),
          if (telegram.queue.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            Text('Recent activity',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const UploadProgressCard(),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.uploaded, required this.bytes});

  final int uploaded;
  final int bytes;

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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.cloud_upload_rounded, color: cs.onPrimary, size: 28),
              const SizedBox(width: 10),
              Text('Your vault',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _stat(context, uploaded.toString(), 'Files backed up'),
              ),
              Container(
                width: 1,
                height: 44,
                color: cs.onPrimary.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _stat(context, _formatBytes(bytes), 'Uploaded'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext ctx, String value, String label) {
    final Color fg = Theme.of(ctx).colorScheme.onPrimary;
    return Column(
      children: <Widget>[
        Text(value,
            style: TextStyle(
              color: fg,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.85),
              fontSize: 12,
            )),
      ],
    );
  }
}
