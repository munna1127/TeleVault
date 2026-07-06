import 'package:permission_handler/permission_handler.dart';

/// Result of a permission request.
class PermissionResult {
  const PermissionResult({
    required this.mediaGranted,
    required this.notificationGranted,
  });

  final bool mediaGranted;
  final bool notificationGranted;

  bool get allGranted => mediaGranted && notificationGranted;
}

/// Utility class for requesting and checking Android runtime permissions.
class PermissionUtils {
  PermissionUtils._();

  /// Requests both media and notification permissions.
  ///
  /// On Android 13+ the granular READ_MEDIA_IMAGES / READ_MEDIA_VIDEO
  /// permissions are used; on older versions READ_EXTERNAL_STORAGE is used
  /// (photo_manager handles this internally via the permission_handler bridge).
  static Future<PermissionResult> requestAll() async {
    final mediaStatus = await _requestMediaPermission();
    final notifStatus = await Permission.notification.request();

    return PermissionResult(
      mediaGranted: mediaStatus,
      notificationGranted: notifStatus.isGranted,
    );
  }

  /// Returns whether media permission is currently granted.
  static Future<bool> hasMediaPermission() async {
    // Android 13+
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    if (photos.isGranted && videos.isGranted) return true;

    // Android ≤12
    final storage = await Permission.storage.status;
    return storage.isGranted;
  }

  /// Opens the app settings page so the user can manually grant permissions.
  static Future<void> openSettings() => openAppSettings();

  // ── Private ───────────────────────────────────────────────────────────────

  static Future<bool> _requestMediaPermission() async {
    // Try granular permissions first (Android 13+).
    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();

    if (photos.isGranted && videos.isGranted) return true;

    // Fall back to storage permission (Android ≤12).
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }
}
