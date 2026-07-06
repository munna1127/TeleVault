import 'package:photo_manager/photo_manager.dart';
import '../models/media_file.dart';

/// Scans the device gallery using MediaStore via the photo_manager package.
class GalleryService {
  /// Returns all [AssetPathEntity] albums on the device.
  Future<List<AssetPathEntity>> getAlbums() async {
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
  }

  /// Counts all photos and videos on the device.
  /// Returns a map with keys 'photos' and 'videos'.
  Future<Map<String, int>> countMedia() async {
    int photos = 0;
    int videos = 0;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    for (final album in albums) {
      // Use the "recent" / all-assets album to avoid double-counting
      if (album.isAll) {
        photos = await PhotoManager.getAssetPathList(
          type: RequestType.image,
        ).then((albums) async {
          int count = 0;
          for (final a in albums) {
            if (a.isAll) count = await a.assetCountAsync;
          }
          return count;
        });

        videos = await PhotoManager.getAssetPathList(
          type: RequestType.video,
        ).then((albums) async {
          int count = 0;
          for (final a in albums) {
            if (a.isAll) count = await a.assetCountAsync;
          }
          return count;
        });
        break;
      }
    }

    return {'photos': photos, 'videos': videos};
  }

  /// Loads all [MediaFile] objects from the device gallery in batches.
  ///
  /// [onProgress] is called after each batch with the running list so far.
  Future<List<MediaFile>> loadAllMedia({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    AssetPathEntity? allAlbum;
    for (final album in albums) {
      if (album.isAll) {
        allAlbum = album;
        break;
      }
    }
    if (allAlbum == null) return [];

    final total = await allAlbum.assetCountAsync;
    const batchSize = 50;
    final result = <MediaFile>[];

    for (int page = 0; page * batchSize < total; page++) {
      final assets = await allAlbum.getAssetListPaged(
        page: page,
        size: batchSize,
      );

      for (final asset in assets) {
        final mediaFile = await MediaFile.fromAsset(asset);
        if (mediaFile != null) result.add(mediaFile);
      }

      onProgress?.call(result.length, total);
    }

    return result;
  }
}
