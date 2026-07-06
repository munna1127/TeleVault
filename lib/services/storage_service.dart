import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// Persists lightweight app state: cumulative counters and uploaded-asset ids.
class StorageService extends ChangeNotifier {
  SharedPreferences? _prefs;

  int _uploadedCount = 0;
  int _uploadedBytes = 0;
  final Set<String> _uploadedIds = <String>{};

  int get uploadedCount => _uploadedCount;
  int get uploadedBytes => _uploadedBytes;
  Set<String> get uploadedIds => Set<String>.unmodifiable(_uploadedIds);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _uploadedCount = _prefs!.getInt(AppConstants.prefUploadedCount) ?? 0;
    _uploadedBytes = _prefs!.getInt(AppConstants.prefUploadedBytes) ?? 0;

    final String? raw = _prefs!.getString(AppConstants.prefUploadedIds);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _uploadedIds
          ..clear()
          ..addAll(decoded.map((dynamic e) => e.toString()));
      } catch (_) {
        // Ignore corrupt cache and start fresh.
      }
    }
    notifyListeners();
  }

  bool isUploaded(String assetId) => _uploadedIds.contains(assetId);

  Future<void> recordUpload({
    required String assetId,
    required int sizeBytes,
  }) async {
    if (_uploadedIds.add(assetId)) {
      _uploadedCount += 1;
      _uploadedBytes += sizeBytes;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _uploadedCount = 0;
    _uploadedBytes = 0;
    _uploadedIds.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final SharedPreferences p = _prefs!;
    await p.setInt(AppConstants.prefUploadedCount, _uploadedCount);
    await p.setInt(AppConstants.prefUploadedBytes, _uploadedBytes);
    await p.setString(
      AppConstants.prefUploadedIds,
      jsonEncode(_uploadedIds.toList()),
    );
  }
}
