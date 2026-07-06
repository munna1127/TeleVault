import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';

/// Settings screen — controls backup preferences and shows app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<BackupService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Telegram section ──────────────────────────────────────────────
          _SectionHeader(label: 'Telegram'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.smart_toy_outlined,
                label: 'Bot Token',
                value: _masked(AppConstants.botToken),
                color: colorScheme.primary,
              ),
              const Divider(height: 1, indent: 52),
              _InfoRow(
                icon: Icons.tag_rounded,
                label: 'Chat ID',
                value: AppConstants.chatId,
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Edit BOT_TOKEN and CHAT_ID in lib/utils/constants.dart '
              'to connect your own Telegram bot.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Backup preferences ────────────────────────────────────────────
          _SectionHeader(label: 'Backup Preferences'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _ToggleRow(
                icon: Icons.sync_rounded,
                label: 'Auto Backup',
                subtitle: 'Back up new media automatically',
                color: colorScheme.primary,
                value: backup.autoBackupEnabled,
                onChanged: backup.setAutoBackup,
              ),
              const Divider(height: 1, indent: 52),
              _ToggleRow(
                icon: Icons.photo_rounded,
                label: 'Backup Photos',
                subtitle: 'Include photos in backups',
                color: colorScheme.primary,
                value: backup.backupPhotos,
                onChanged: backup.setBackupPhotos,
              ),
              const Divider(height: 1, indent: 52),
              _ToggleRow(
                icon: Icons.videocam_rounded,
                label: 'Backup Videos',
                subtitle: 'Include videos in backups',
                color: Colors.deepPurple,
                value: backup.backupVideos,
                onChanged: backup.setBackupVideos,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionHeader(label: 'Notifications'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: 'Backup Notifications',
                subtitle: 'Notify on backup start and completion',
                color: Colors.orange,
                value: backup.notificationsEnabled,
                onChanged: backup.setNotifications,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                value: '1.0.0',
                color: colorScheme.secondary,
              ),
              const Divider(height: 1, indent: 52),
              _InfoRow(
                icon: Icons.cloud_upload_outlined,
                label: 'App',
                value: AppConstants.appName,
                color: colorScheme.secondary,
              ),
              const Divider(height: 1, indent: 52),
              _InfoRow(
                icon: Icons.storage_rounded,
                label: 'Telegram Limit',
                value: '50 MB per file',
                color: colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Masks all but the last 4 characters of a token.
  static String _masked(String token) {
    if (token.length <= 4) return '****';
    return '•' * (token.length - 4) + token.substring(token.length - 4);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
