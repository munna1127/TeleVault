/// TeleVault configuration.
///
/// 1. Create a bot with @BotFather on Telegram and copy its token.
/// 2. Send any message to the bot (or add it to a group / channel).
/// 3. Visit `https://api.telegram.org/bot<TOKEN>/getUpdates` and copy the
///    numeric `chat.id` value.
/// 4. Paste both strings below, then run `flutter run`.
class AppConstants {
  AppConstants._();

  /// Telegram Bot API token from @BotFather. Example:
  /// `123456789:ABCdefGhIJKlmNoPQRstuVWXyz1234567890`
  static const String botToken = '8051346795:AAFezc4OtN12qmG6f2EJR2cfkydGFA77pxQ';

  /// The chat ID to upload to. Can be a positive integer (private chat with
  /// your bot) or a negative integer (group / channel), passed as a String.
  static const String chatId = '6508791739';

  /// Telegram Bot API upload limit (bytes). 50 MB per file.
  static const int telegramMaxUploadBytes = 50 * 1024 * 1024;

  /// User-visible name.
  static const String appName = 'TeleVault';

  /// SharedPreferences key for cumulative uploaded file count.
  static const String prefUploadedCount = 'televault.uploaded_count';

  /// SharedPreferences key for cumulative uploaded bytes.
  static const String prefUploadedBytes = 'televault.uploaded_bytes';

  /// SharedPreferences key holding the JSON list of uploaded asset ids so we
  /// don't count the same file twice.
  static const String prefUploadedIds = 'televault.uploaded_ids';

  /// Returns true when both required constants have been filled in.
  static bool get isConfigured =>
      botToken.trim().isNotEmpty && chatId.trim().isNotEmpty;
}
