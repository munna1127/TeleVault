import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../models/media_file.dart';
import '../utils/constants.dart';

/// Result of a single file upload attempt.
class UploadResult {
  const UploadResult({
    required this.file,
    required this.success,
    this.errorMessage,
  });

  final MediaFile file;
  final bool success;
  final String? errorMessage;
}

/// Handles all Telegram Bot API communication.
///
/// Upload logic:
///  - Photos  → sendPhoto  (multipart/form-data)
///  - Videos  → sendVideo  (multipart/form-data)
///  - Files > 50 MB are skipped with an error result.
class TelegramService {
  TelegramService._();

  static final TelegramService instance = TelegramService._();

  /// Files uploaded in the **current session** (by MediaFile.id) to avoid
  /// re-sending the same file when the user taps "Backup Now" multiple times.
  final Set<String> _uploadedIds = {};

  /// Clear the session upload cache (e.g. on app restart).
  void clearSession() => _uploadedIds.clear();

  /// Whether [file] was already uploaded this session.
  bool isAlreadyUploaded(MediaFile file) => _uploadedIds.contains(file.id);

  /// Sends a text message to the configured chat.
  Future<bool> sendMessage(String text) async {
    try {
      final uri = Uri.parse('${AppConstants.telegramBaseUrl}/sendMessage');
      final response = await http
          .post(uri, body: {'chat_id': AppConstants.chatId, 'text': text})
          .timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Uploads a single [MediaFile] to Telegram.
  ///
  /// Returns an [UploadResult] indicating success or failure.
  Future<UploadResult> uploadFile(MediaFile file) async {
    // Skip files already uploaded this session.
    if (_uploadedIds.contains(file.id)) {
      return UploadResult(
        file: file,
        success: true,
        errorMessage: 'Already uploaded this session',
      );
    }

    // Skip oversized files.
    if (!file.isWithinSizeLimit) {
      return UploadResult(
        file: file,
        success: false,
        errorMessage: 'File too large (${file.formattedSize}). '
            'Telegram limit is 50 MB.',
      );
    }

    final ioFile = File(file.path);
    if (!await ioFile.exists()) {
      return UploadResult(
        file: file,
        success: false,
        errorMessage: 'File not found on device',
      );
    }

    try {
      final endpoint = file.type == MediaType.photo ? 'sendPhoto' : 'sendVideo';
      final fieldName = file.type == MediaType.photo ? 'photo' : 'video';
      final uri = Uri.parse('${AppConstants.telegramBaseUrl}/$endpoint');

      final mimeType =
          lookupMimeType(file.path) ??
          (file.type == MediaType.photo ? 'image/jpeg' : 'video/mp4');

      final request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = AppConstants.chatId
        ..fields['caption'] = '📁 ${file.name}'
        ..files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType:
                _parseMediaType(mimeType),
          ),
        );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      if (streamedResponse.statusCode == 200) {
        _uploadedIds.add(file.id);
        return UploadResult(file: file, success: true);
      } else {
        final body = await streamedResponse.stream.bytesToString();
        return UploadResult(
          file: file,
          success: false,
          errorMessage:
              'HTTP ${streamedResponse.statusCode}: $body',
        );
      }
    } on SocketException catch (e) {
      return UploadResult(
        file: file,
        success: false,
        errorMessage: 'Network error: ${e.message}',
      );
    } on HttpException catch (e) {
      return UploadResult(
        file: file,
        success: false,
        errorMessage: 'HTTP error: ${e.message}',
      );
    } catch (e) {
      return UploadResult(
        file: file,
        success: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  /// Uploads multiple files, calling [onProgress] after each attempt.
  ///
  /// Errors on individual files do NOT stop the upload; the process
  /// continues with the remaining files.
  Future<List<UploadResult>> uploadAll(
    List<MediaFile> files, {
    void Function(int done, int total, UploadResult latest)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final results = <UploadResult>[];

    for (int i = 0; i < files.length; i++) {
      if (isCancelled != null && isCancelled()) break;

      final result = await uploadFile(files[i]);
      results.add(result);
      onProgress?.call(i + 1, files.length, result);
    }

    return results;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parses a MIME type string into an http.MediaType.
  http.MediaType _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) return http.MediaType(parts[0], parts[1]);
    return http.MediaType('application', 'octet-stream');
  }
}
