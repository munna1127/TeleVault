import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../services/telegram_service.dart';
import '../widgets/upload_progress_card.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const int _pageSize = 90;

  final List<AssetEntity> _assets = <AssetEntity>[];
  final Set<String> _selected = <String>{};

  AssetPathEntity? _album;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.common, // photos + videos
      );
      if (paths.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No gallery albums found on this device.';
        });
        return;
      }
      _album = paths.first;
      _page = 0;
      _hasMore = true;
      _assets.clear();
      await _loadMore();
    } catch (e) {
      setState(() {
        _error = 'Failed to read gallery: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _album == null) return;
    setState(() => _loadingMore = true);
    try {
      final List<AssetEntity> batch = await _album!.getAssetListPaged(
        page: _page,
        size: _pageSize,
      );
      if (batch.length < _pageSize) _hasMore = false;
      _assets.addAll(batch);
      _page += 1;
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (!_selected.remove(asset.id)) {
        _selected.add(asset.id);
      }
    });
  }

  Future<void> _upload() async {
    final List<AssetEntity> chosen = _assets
        .where((AssetEntity a) => _selected.contains(a.id))
        .toList(growable: false);
    if (chosen.isEmpty) return;

    final TelegramService svc = context.read<TelegramService>();
    _selected.clear();
    setState(() {});
    await svc.enqueueAndStart(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final StorageService storage = context.watch<StorageService>();
    final TelegramService telegram = context.watch<TelegramService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.isEmpty
            ? 'Gallery'
            : '${_selected.length} selected'),
        actions: <Widget>[
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(_selected.clear),
            ),
        ],
      ),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _upload,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text('Upload ${_selected.length}'),
            ),
      body: Column(
        children: <Widget>[
          if (telegram.queue.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: UploadProgressCard(),
            ),
          Expanded(child: _buildBody(storage)),
        ],
      ),
    );
  }

  Widget _buildBody(StorageService storage) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    if (_assets.isEmpty) {
      return const Center(child: Text('No photos or videos here yet.'));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _assets.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext ctx, int index) {
          if (index >= _assets.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final AssetEntity asset = _assets[index];
          final bool selected = _selected.contains(asset.id);
          final bool uploaded = storage.isUploaded(asset.id);
          return _MediaTile(
            asset: asset,
            selected: selected,
            uploaded: uploaded,
            onTap: () => _toggle(asset),
          );
        },
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.asset,
    required this.selected,
    required this.uploaded,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(240),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: cs.surfaceContainerHighest),
            ),
          ),
          if (asset.type == AssetType.video)
            Positioned(
              left: 6,
              bottom: 6,
              child: _pill(
                icon: Icons.play_arrow_rounded,
                label: _formatDuration(asset.videoDuration),
                cs: cs,
              ),
            ),
          if (uploaded)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.tertiary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.check, size: 14, color: cs.onTertiary),
              ),
            ),
          if (selected)
            Container(
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary, width: 2),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.check_circle,
                      color: cs.primary, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(
      {required IconData icon, required String label, required ColorScheme cs}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
