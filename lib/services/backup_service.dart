import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_file.dart';
import '../models/backup_stats.dart';
import '../services/gallery_service.dart';
import '../services/telegram_service.dart';
import '../utils/constants.dart';

/// Overall state of the backup process.
enum BackupState { idle, scanning, uploading, done, error }

/// Notifier that drives both HomeScreen state and ProgressDialog.
class BackupService extends ChangeNotifier {
  BackupService({
    required GalleryService galleryService,
    required TelegramService telegramService,
  })  : _galleryService = galleryService,
        _telegram = telegramService;

  final GalleryService _galleryService;
  final TelegramService _telegram;

  // ── Exposed state ─────────────────────────────────────────────────────────
  BackupStats stats = const BackupStats();
  BackupState backupState = BackupState.idle;

  bool autoBackupEnabled = false;
  bool notificationsEnabled = true;
  bool backupPhotos = true;
  bool backupVideos = true;

  /// Current upload index (1-based) during an active upload.
  int uploadCurrent = 0;

  /// Total files queued for the current upload.
  int uploadTotal = 0;

  /// Latest upload result message.
  String uploadStatusMessage = '';

  /// Running counts for the last backup operation.
  int lastSuccessCount = 0;
  int lastFailCount = 0;

  String? errorMessage;

  bool _cancelled = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Load settings and last backup time from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    autoBackupEnabled =
        prefs.getBool(AppConstants.keyAutoBackupEnabled) ?? false;
    notificationsEnabled =
        prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    backupPhotos = prefs.getBool(AppConstants.keyBackupPhotos) ?? true;
    backupVideos = prefs.getBool(AppConstants.keyBackupVideos) ?? true;

    final lastMs = prefs.getInt(AppConstants.keyLastBackupTime);
    final lastTime =
        lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

    stats = stats.copyWith(lastBackupTime: lastTime);
    notifyListeners();
  }

  // ── Gallery scan ──────────────────────────────────────────────────────────

  /// Scans the device gallery and updates [stats].
  Future<void> scanGallery() async {
    stats = stats.copyWith(isScanning: true);
    backupState = BackupState.scanning;
    notifyListeners();

    try {
      final counts = await _galleryService.countMedia();
      stats = stats.copyWith(
        totalPhotos: counts['photos'] ?? 0,
        totalVideos: counts['videos'] ?? 0,
        isScanning: false,
      );
      backupState = BackupState.idle;
    } catch (e) {
      stats = stats.copyWith(isScanning: false);
      backupState = BackupState.error;
      errorMessage = 'Failed to scan gallery: $e';
    }

    notifyListeners();
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  /// Loads all media and uploads them to Telegram.
  Future<void> startBackup() async {
    if (backupState == BackupState.uploading) return;

    _cancelled = false;
    backupState = BackupState.scanning;
    uploadCurrent = 0;
    uploadTotal = 0;
    lastSuccessCount = 0;
    lastFailCount = 0;
    uploadStatusMessage = 'Loading media from gallery…';
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Load media files.
      final all = await _galleryService.loadAllMedia();

      // 2. Filter based on settings.
      final filtered = all.where((f) {
        if (f.type == MediaType.photo && !backupPhotos) return false;
        if (f.type == MediaType.video && !backupVideos) return false;
        return true;
      }).toList();

      if (filtered.isEmpty) {
        backupState = BackupState.done;
        uploadStatusMessage = 'No media to back up.';
        notifyListeners();
        return;
      }

      uploadTotal = filtered.length;
      backupState = BackupState.uploading;
      notifyListeners();

      // 3. Upload each file.
      await _telegram.uploadAll(
        filtered,
        isCancelled: () => _cancelled,
        onProgress: (done, total, result) {
          uploadCurrent = done;
          uploadTotal = total;
          if (result.success) {
            lastSuccessCount++;
            uploadStatusMessage =
                '✅ Uploaded: ${result.file.name}';
          } else {
            lastFailCount++;
            uploadStatusMessage =
                '⚠️ Skipped: ${result.file.name}\n'
                '${result.errorMessage ?? 'Unknown error'}';
          }
          notifyListeners();
        },
      );

      // 4. Persist last backup time.
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.keyLastBackupTime,
        now.millisecondsSinceEpoch,
      );
      stats = stats.copyWith(lastBackupTime: now);

      backupState = BackupState.done;
      uploadStatusMessage =
          'Backup complete — $lastSuccessCount uploaded, '
          '$lastFailCount skipped.';
    } catch (e) {
      backupState = BackupState.error;
      errorMessage = 'Backup failed: $e';
      uploadStatusMessage = errorMessage!;
    }

    notifyListeners();
  }

  /// Cancel an in-progress upload.
  void cancelBackup() {
    _cancelled = true;
    backupState = BackupState.idle;
    uploadStatusMessage = 'Backup cancelled.';
    notifyListeners();
  }

  void resetToIdle() {
    backupState = BackupState.idle;
    errorMessage = null;
    notifyListeners();
  }

  // ── Settings persistence ──────────────────────────────────────────────────

  Future<void> setAutoBackup(bool value) async {
    autoBackupEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoBackupEnabled, value);
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
  }

  Future<void> setBackupPhotos(bool value) async {
    backupPhotos = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBackupPhotos, value);
  }

  Future<void> setBackupVideos(bool value) async {
    backupVideos = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBackupVideos, value);
  }
}
