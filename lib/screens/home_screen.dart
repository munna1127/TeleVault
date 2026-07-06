import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/progress_dialog.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';

/// Main screen — shows gallery stats and backup controls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the gallery scan after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupService>().scanGallery();
    });
  }

  Future<void> _handleBackupNow() async {
    final backup = context.read<BackupService>();
    if (backup.backupState == BackupState.uploading) return;

    // Show progress sheet first, then start backup.
    backup.startBackup();
    await ProgressDialog.show(context);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<BackupService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = backup.stats;
    final isScanning = stats.isScanning;
    final isUploading = backup.backupState == BackupState.uploading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: backup.scanGallery,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Status banner ───────────────────────────────────────────────
            _StatusBanner(backupState: backup.backupState),
            const SizedBox(height: 24),

            // ── Stats grid ──────────────────────────────────────────────────
            Text(
              'Your Gallery',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Photos',
                    value: isScanning
                        ? '—'
                        : stats.totalPhotos.toString(),
                    icon: Icons.photo_rounded,
                    iconColor: colorScheme.primary,
                    isLoading: isScanning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Videos',
                    value: isScanning
                        ? '—'
                        : stats.totalVideos.toString(),
                    icon: Icons.videocam_rounded,
                    iconColor: Colors.deepPurple,
                    isLoading: isScanning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StatCard(
              label: 'Last Backup',
              value: _formatDate(stats.lastBackupTime),
              icon: Icons.history_rounded,
              iconColor: Colors.teal,
              isLoading: isScanning,
            ),
            const SizedBox(height: 28),

            // ── Backup controls ─────────────────────────────────────────────
            Text(
              'Backup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Auto-backup toggle
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sync_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Backup',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Automatically back up new photos and videos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: backup.autoBackupEnabled,
                      onChanged: backup.setAutoBackup,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Backup Now button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: isUploading || isScanning ? null : _handleBackupNow,
                icon: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 22),
                label: Text(
                  isUploading ? 'Uploading…' : 'Backup Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Refresh button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: isScanning ? null : backup.scanGallery,
                icon: isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(isScanning ? 'Scanning…' : 'Refresh Gallery'),
              ),
            ),

            // Error display
            if (backup.backupState == BackupState.error &&
                backup.errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        backup.errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    IconButton(
                      onPressed: backup.resetToIdle,
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Info footer ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Files > 50 MB are automatically skipped '
                      '(Telegram upload limit).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact banner shown at the top of HomeScreen during active operations.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.backupState});

  final BackupState backupState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String? message;
    Color? bg;
    Color? fg;
    IconData? icon;

    switch (backupState) {
      case BackupState.scanning:
        message = 'Scanning your gallery…';
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        icon = Icons.image_search_rounded;
      case BackupState.uploading:
        message = 'Backup in progress…';
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        icon = Icons.cloud_upload_outlined;
      case BackupState.done:
        message = 'Backup complete!';
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        icon = Icons.check_circle_outline_rounded;
      case BackupState.error:
        return const SizedBox.shrink();
      case BackupState.idle:
        return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
