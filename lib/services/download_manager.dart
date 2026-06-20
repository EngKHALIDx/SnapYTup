import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';
import '../models/media_item.dart';
import 'youtube_service.dart';

/// Manages download tasks with these guarantees:
/// 1. Files are saved to /Android/data/&lt;pkg&gt;/files/MediaGrab/{Videos|Music}/
///    — works on Android 10+ without MANAGE_EXTERNAL_STORAGE.
/// 2. Pause/resume uses HTTP Range headers when the server supports it
///    (most CDNs do), so resume continues from where it left off.
/// 3. Concurrent downloads are limited to 3 to avoid saturating the network.
/// 4. Each task gets a unique id; the UI rebuilds whenever any field changes
///    because we replace the entire state list with a new List reference.
/// 5. Failed downloads show the actual error message.
class DownloadManager extends StateNotifier<List<DownloadTask>> {
  DownloadManager() : super([]);
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 30),
    sendTimeout: const Duration(seconds: 15),
    followRedirects: true,
    maxRedirects: 5,
  ));
  final Map<String, CancelToken> _cancelers = {};
  static const int _maxConcurrent = 3;
  int _activeCount = 0;

  Future<Directory> _dir(bool audio) async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final sub = audio ? 'Music' : 'Videos';
    final d = Directory(p.join(base.path, 'MediaGrab', sub));
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  String _safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_').trim();
    return cleaned.isEmpty ? 'media_${DateTime.now().millisecondsSinceEpoch}' : cleaned;
  }

  /// Enqueue a new download. Returns the task id (empty string on failure).
  Future<String> enqueue({
    required MediaItem media,
    required String streamUrl,
    required String quality,
    required String format,
    required bool isAudio,
  }) async {
    if (streamUrl.isEmpty) {
      return '';
    }
    final dir = await _dir(isAudio);
    final name = _safeName('${media.author ?? ''} ${media.title}'.trim());
    // Avoid filename collisions: if file exists, append (1), (2), ...
    var savePath = p.join(dir.path, '$name.$format');
    var counter = 1;
    while (File(savePath).existsSync()) {
      savePath = p.join(dir.path, '$name ($counter).$format');
      counter++;
    }
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      media: media.copyWith(streamUrl: streamUrl),
      quality: quality,
      format: format,
      savePath: savePath,
      isAudio: isAudio,
    );
    state = [...state, task];
    _runIfSlot(task);
    return task.id;
  }

  void pause(String id) {
    final canceler = _cancelers[id];
    if (canceler != null && !canceler.isCancelled) {
      canceler.cancel('paused');
    }
    _update(id, (t) => t.state = DownloadState.paused);
  }

  void resume(String id) {
    final t = _find(id);
    if (t != null &&
        (t.state == DownloadState.paused || t.state == DownloadState.failed)) {
      _runIfSlot(t);
    }
  }

  void cancel(String id) {
    final canceler = _cancelers[id];
    if (canceler != null && !canceler.isCancelled) {
      canceler.cancel('canceled');
    }
    _update(id, (t) => t.state = DownloadState.failed);
  }

  void remove(String id) {
    cancel(id);
    state = state.where((t) => t.id != id).toList();
  }

  /// Retry a failed/canceled task.
  void retry(String id) {
    final t = _find(id);
    if (t == null || !t.canRetry) return;
    t
      ..progress = 0
      ..downloadedBytes = 0
      ..totalBytes = 0
      ..error = null;
    _runIfSlot(t);
  }

  /// Clear all completed/failed tasks (keeps only active + queued).
  void clearFinished() {
    state = state.where((t) => t.isActive).toList();
  }

  DownloadTask? _find(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _update(String id, void Function(DownloadTask) fn) {
    final t = _find(id);
    if (t == null) return;
    fn(t);
    state = [...state];
  }

  /// Run a task if the concurrency slot is available; otherwise queue it.
  void _runIfSlot(DownloadTask task) {
    if (_activeCount >= _maxConcurrent) {
      _update(task.id, (t) => t.state = DownloadState.queued);
      return;
    }
    _run(task);
  }

  /// Check if any queued task can be started now.
  void _pumpQueue() {
    if (_activeCount >= _maxConcurrent) return;
    final queued = state
        .where((t) => t.state == DownloadState.queued)
        .toList();
    for (final t in queued) {
      if (_activeCount >= _maxConcurrent) break;
      _run(t);
    }
  }

  Future<void> _run(DownloadTask task) async {
    final canceler = CancelToken();
    _cancelers[task.id] = canceler;
    _activeCount++;
    task
      ..state = DownloadState.running
      ..startTime = DateTime.now()
      ..error = null;
    state = [...state];

    try {
      await _downloadWithRetry(task, canceler, maxRetries: 2);
      task
        ..state = DownloadState.completed
        ..progress = 1
        ..endTime = DateTime.now();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Pause/cancel already set the state; don't overwrite.
      } else {
        task
          ..state = DownloadState.failed
          ..error = _dioError(e);
      }
    } on ArgumentError catch (e) {
      task
        ..state = DownloadState.failed
        ..error = e.message?.toString() ?? 'رابط غير صالح';
    } catch (e) {
      task
        ..state = DownloadState.failed
        ..error = _translateError(e);
    } finally {
      _cancelers.remove(task.id);
      _activeCount--;
      state = [...state];
      _pumpQueue();
    }
  }

  /// Download with retry: if the URL returns 403 (expired), refresh
  /// qualities from YouTubeService and try again with the new URL.
  Future<void> _downloadWithRetry(DownloadTask task, CancelToken canceler, {required int maxRetries}) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final urlStr = task.media.streamUrl;
        if (urlStr == null || urlStr.isEmpty) {
          throw ArgumentError('رابط التنزيل فارغ');
        }
        final uri = Uri.parse(urlStr);
        if (!uri.hasScheme || !uri.scheme.startsWith('http')) {
          throw ArgumentError('رابط التنزيل غير صالح');
        }

        final file = File(task.savePath);
        final existingLength = file.existsSync() ? await file.length() : 0;
        final headers = <String, dynamic>{
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://www.youtube.com/',
          'Origin': 'https://www.youtube.com',
        };
        if (existingLength > 0) {
          headers['Range'] = 'bytes=$existingLength-';
        }

        await _dio.downloadUri(
          uri,
          task.savePath,
          cancelToken: canceler,
          options: Options(
            headers: headers,
            receiveTimeout: const Duration(minutes: 30),
            followRedirects: true,
            maxRedirects: 5,
          ),
          onReceiveProgress: (received, total) {
            final effectiveTotal = existingLength > 0 && total > 0
                ? existingLength + total
                : total;
            task
              ..downloadedBytes = existingLength + received
              ..totalBytes = effectiveTotal
              ..progress = effectiveTotal > 0
                  ? (existingLength + received) / effectiveTotal
                  : 0;
            state = [...state];
          },
        );
        return; // Success
      } on DioException catch (e) {
        // If 403 (URL expired) and this is a YouTube video, refresh URL and retry
        final isExpired = e.response?.statusCode == 403 || e.response?.statusCode == 410;
        final isYouTube = task.media.platform == Platform.youtube;
        if (isExpired && isYouTube && attempt < maxRetries) {
          // Try to refresh the URL from YouTubeService
          final freshUrl = await _refreshYouTubeUrl(task);
          if (freshUrl != null) {
            // Update the task's streamUrl in-place and retry
            task.media = task.media.copyWith(streamUrl: freshUrl);
            state = [...state];
            continue; // retry with new URL
          }
        }
        rethrow;
      }
    }
  }

  /// Refresh a YouTube stream URL by re-fetching qualities and finding
  /// one that matches the task's quality label.
  Future<String?> _refreshYouTubeUrl(DownloadTask task) async {
    try {
      final svc = YouTubeService();
      final qualities = await svc.getQualities(task.media.id);
      svc.dispose();
      // Find a quality that matches what the user originally selected
      final match = qualities.where((q) =>
        q.label.contains(task.quality) ||
        task.quality.contains(q.label) ||
        (q.isAudio == task.isAudio && q.label == task.quality)
      ).firstOrNull;
      return match?.url;
    } catch (_) {
      return null;
    }
  }

  /// Translate generic exceptions to Arabic messages that match the UI.
  String _translateError(dynamic e) {
    final s = e.toString();
    if (s.contains('403') || s.contains('Forbidden')) {
      return 'الخادم رفض الطلب (403). قد يكون الرابط منتهي الصلاحية.';
    }
    if (s.contains('404') || s.contains('Not Found')) {
      return 'الملف غير موجود (404)';
    }
    if (s.contains('SocketException') || s.contains('Connection refused')) {
      return 'تعذر الاتصال بالإنترنت';
    }
    if (s.contains('HandshakeException') || s.contains('TLS')) {
      return 'فشل التحقق من شهادة SSL';
    }
    if (s.length > 100) {
      return 'فشل غير متوقع: ${s.substring(0, 100)}';
    }
    return s;
  }

  String _dioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الإرسال';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاستقبال';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return code == 403
            ? 'الخادم رفض الطلب (403)'
            : code == 404
                ? 'الملف غير موجود (404)'
                : 'خطأ في الاستجابة ($code)';
      case DioExceptionType.cancel:
        return 'تم الإلغاء';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالإنترنت';
      default:
        return e.message ?? 'فشل التنزيل';
    }
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManager, List<DownloadTask>>((ref) => DownloadManager());
