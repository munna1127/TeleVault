import 'package:photo_manager/photo_manager.dart';

/// Type of media asset.
enum MediaType { photo, video }

/// Represents a single photo or video from the device gallery.
class MediaFile {
  const MediaFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.sizeBytes,
    required this.createdAt,
  });

  /// Unique asset ID from MediaStore.
  final String id;

  /// Display filename.
  final String name;

  /// Absolute file-system path.
  final String path;

  final MediaType type;

  /// File size in bytes.
  final int sizeBytes;

  final DateTime createdAt;

  /// Build a [MediaFile] from a photo_manager [AssetEntity].
  static Future<MediaFile?> fromAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    return MediaFile(
      id: asset.id,
      name: asset.title ?? file.path.split('/').last,
      path: file.path,
      type: asset.type == AssetType.video ? MediaType.video : MediaType.photo,
      sizeBytes: await file.length(),
      createdAt: asset.createDateTime,
    );
  }

  /// Whether the file is within Telegram's 50 MB upload limit.
  bool get isWithinSizeLimit => sizeBytes <= 50 * 1024 * 1024;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'MediaFile(id: $id, name: $name, type: $type)';
}
