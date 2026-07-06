/// App-wide constants for TeleVault.
/// Replace BOT_TOKEN and CHAT_ID with your actual Telegram credentials.
class AppConstants {
  AppConstants._();

  // ── Telegram Bot API ─────────────────────────────────────────────────────
  /// Your Telegram Bot token from @BotFather.
  static const String botToken = 'YOUR_BOT_TOKEN_HERE';

  /// The chat / channel ID where backups will be sent.
  static const String chatId = 'YOUR_CHAT_ID_HERE';

  /// Telegram Bot API base URL.
  static const String telegramBaseUrl = 'https://api.telegram.org/bot$botToken';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String keyLastBackupTime = 'last_backup_time';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBackupPhotos = 'backup_photos';
  static const String keyBackupVideos = 'backup_videos';

  // ── UI ────────────────────────────────────────────────────────────────────
  static const String appName = 'TeleVault';
  static const String appTagline = 'Your gallery, safely vaulted.';

  /// Max size (bytes) of a single Telegram upload before we split/skip (50 MB).
  static const int maxUploadBytes = 50 * 1024 * 1024;
}
