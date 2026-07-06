import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../constants.dart';
import 'storage_service.dart';

enum UploadPhase { pending, uploading, done, error, skipped }

class UploadItem {
  UploadItem({
    required this.asset,
    required this.fileName,
    required this.sizeBytes,
  });

  final AssetEntity asset;
  final String fileName;
  final int sizeBytes;

  UploadPhase phase = UploadPhase.pending;
  double progress = 0;
  String? errorMessage;
}

/// Uploads media to Telegram via the Bot API using a Dio client.
class TelegramService extends ChangeNotifier {
  TelegramService({required this.storage}) : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 10),
            receiveTimeout: const Duration(minutes: 2),
          ),
        );

  final StorageService storage;
  final Dio _dio;

  final List<UploadItem> _queue = <UploadItem>[];
  bool _isRunning = false;
  bool _cancelRequested = false;

  List<UploadItem> get queue => List<UploadItem>.unmodifiable(_queue);
  bool get isRunning => _isRunning;

  int get completedCount =>
      _queue.where((UploadItem i) => i.phase == UploadPhase.done).length;
  int get failedCount =>
      _queue.where((UploadItem i) => i.phase == UploadPhase.error).length;
  int get skippedCount =>
      _queue.where((UploadItem i) => i.phase == UploadPhase.skipped).length;

  double get overallProgress {
    if (_queue.isEmpty) return 0;
    final double sum = _queue.fold<double>(
      0,
      (double acc, UploadItem i) => acc +
          switch (i.phase) {
            UploadPhase.done => 1.0,
            UploadPhase.error || UploadPhase.skipped => 1.0,
            UploadPhase.uploading => i.progress,
            UploadPhase.pending => 0.0,
          },
    );
    return sum / _queue.length;
  }

  void cancel() {
    if (!_isRunning) return;
    _cancelRequested = true;
  }

  void clear() {
    if (_isRunning) return;
    _queue.clear();
    notifyListeners();
  }

  /// Adds new assets and immediately begins uploading if idle.
  Future<void> enqueueAndStart(List<AssetEntity> assets) async {
    for (final AssetEntity asset in assets) {
      final File? file = await asset.originFile;
      if (file == null) continue;
      final int size = await file.length();
      _queue.add(UploadItem(
        asset: asset,
        fileName: await _fileNameFor(asset, file),
        sizeBytes: size,
      ));
    }
    notifyListeners();
    if (!_isRunning) {
      unawaited(_drainQueue());
    }
  }

  Future<String> _fileNameFor(AssetEntity asset, File file) async {
    final String? title = await asset.titleAsync;
    if (title != null && title.isNotEmpty) return title;
    return file.path.split(Platform.pathSeparator).last;
  }

  Future<void> _drainQueue() async {
    if (!AppConstants.isConfigured) {
      for (final UploadItem item in _queue) {
        if (item.phase == UploadPhase.pending) {
          item.phase = UploadPhase.error;
          item.errorMessage =
              'Bot token / chat id not configured in lib/constants.dart';
        }
      }
      notifyListeners();
      return;
    }

    _isRunning = true;
    _cancelRequested = false;
    notifyListeners();

    for (final UploadItem item in _queue) {
      if (_cancelRequested) break;
      if (item.phase != UploadPhase.pending) continue;
      await _uploadOne(item);
    }

    _isRunning = false;
    _cancelRequested = false;
    notifyListeners();
  }

  Future<void> _uploadOne(UploadItem item) async {
    if (item.sizeBytes > AppConstants.telegramMaxUploadBytes) {
      item.phase = UploadPhase.skipped;
      item.errorMessage =
          'Larger than Telegram Bot API 50 MB per-file limit.';
      notifyListeners();
      return;
    }

    final File? file = await item.asset.originFile;
    if (file == null || !await file.exists()) {
      item.phase = UploadPhase.error;
      item.errorMessage = 'Original file could not be read.';
      notifyListeners();
      return;
    }

    item.phase = UploadPhase.uploading;
    item.progress = 0;
    notifyListeners();

    try {
      final bool isVideo = item.asset.type == AssetType.video;
      final String endpoint = isVideo ? 'sendVideo' : 'sendPhoto';
      final String fieldName = isVideo ? 'video' : 'photo';

      final FormData form = FormData.fromMap(<String, dynamic>{
        'chat_id': AppConstants.chatId,
        'caption': '${item.fileName}  •  TeleVault',
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: item.fileName,
        ),
      });

      final Response<dynamic> resp = await _dio.post<dynamic>(
        'https://api.telegram.org/bot${AppConstants.botToken}/$endpoint',
        data: form,
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            item.progress = sent / total;
            notifyListeners();
          }
        },
      );

      final Map<String, dynamic> data =
          (resp.data as Map<dynamic, dynamic>).cast<String, dynamic>();
      if (data['ok'] == true) {
        item.phase = UploadPhase.done;
        item.progress = 1;
        await storage.recordUpload(
          assetId: item.asset.id,
          sizeBytes: item.sizeBytes,
        );
      } else {
        item.phase = UploadPhase.error;
        item.errorMessage =
            (data['description'] ?? 'Telegram rejected the file.').toString();
      }
    } on DioException catch (e) {
      item.phase = UploadPhase.error;
      final dynamic body = e.response?.data;
      String? description;
      if (body is Map && body['description'] is String) {
        description = body['description'] as String;
      }
      item.errorMessage = description ?? e.message ?? 'Network error';
    } catch (e) {
      item.phase = UploadPhase.error;
      item.errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
