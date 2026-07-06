import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// Wraps runtime permission requests for the gallery.
class PermissionService {
  const PermissionService();

  /// Requests everything the app needs to browse the gallery.
  ///
  /// Returns true when the app can read at least images. `photo_manager` is
  /// asked first so we get the Android 13+ granular media permissions and
  /// iOS PHPhotoLibrary all at once.
  Future<PermissionOutcome> ensureGalleryAccess() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();

    if (state.isAuth) {
      return const PermissionOutcome(granted: true, limited: false);
    }
    if (state == PermissionState.limited) {
      return const PermissionOutcome(granted: true, limited: true);
    }

    // Fallback for older Android versions where photo_manager may not map
    // things cleanly.
    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> results =
          await <Permission>[
        Permission.photos,
        Permission.videos,
        Permission.storage,
      ].request();

      final bool anyGranted =
          results.values.any((PermissionStatus s) => s.isGranted);
      if (anyGranted) {
        return const PermissionOutcome(granted: true, limited: false);
      }

      final bool permanentlyDenied = results.values
          .any((PermissionStatus s) => s.isPermanentlyDenied);
      return PermissionOutcome(
        granted: false,
        limited: false,
        permanentlyDenied: permanentlyDenied,
      );
    }

    return const PermissionOutcome(granted: false, limited: false);
  }

  Future<void> openSettings() => openAppSettings();
}

class PermissionOutcome {
  const PermissionOutcome({
    required this.granted,
    required this.limited,
    this.permanentlyDenied = false,
  });

  final bool granted;
  final bool limited;
  final bool permanentlyDenied;
}
