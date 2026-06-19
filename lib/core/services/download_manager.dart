import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/download_task.dart';
import '../models/media_item.dart';
import '../utils/storage_utils.dart';

/// Notifier exposing the live download queue and giving the UI a way to
/// add, pause, resume, cancel or retry downloads.
class DownloadManager extends StateNotifier<List<DownloadTask>> {
  DownloadManager() : super([]);

  final Dio _dio = Dio();
  final _uuid = const Uuid();

  /// Active cancellers keyed by task id.
  final Map<String, CancelToken> _cancelers = {};

  /// Stream of progress updates per task (broadcast so multiple listeners work).
  final Map<String, StreamController<DownloadTask>> _controllers = {};

  /// Subscribe to live updates for a single task.
  Stream<DownloadTask> watch(String taskId) {
    return _controllers.putIfAbsent(
      taskId,
      () => StreamController<DownloadTask>.broadcast(),
    ).stream;
  }

  /// All tasks (active + completed) in insertion order.
  List<DownloadTask> get all => List.unmodifiable(state);

  /// Just the active ones.
  List<DownloadTask> get active =>
      state.where((t) => t.isActive).toList(growable: false);

  /// Just the completed ones.
  List<DownloadTask> get completed =>
      state.where((t) => t.status == DownloadStatus.completed).toList(growable: false);

  /// Enqueue a new download.
  ///
  /// [streamUrl] is the direct URL to the actual media file. If the caller
  /// only has a [MediaItem] without a [MediaItem.streamUrl], they should
  /// resolve one via the appropriate repository first.
  Future<String> enqueue({
    required MediaItem media,
    required String quality,
    required String format,
    required bool extractAudio,
  }) async {
    final streamUrl = media.streamUrl;
    if (streamUrl == null || streamUrl.isEmpty) {
      throw ArgumentError('MediaItem.streamUrl must be set before enqueuing.');
    }

    // Determine the destination directory.
    final dir = extractAudio
        ? await StorageUtils.musicDir()
        : await StorageUtils.videosDir();

    final savePath = StorageUtils.buildPath(
      dir,
      '${media.author ?? 'media'} - ${media.title}',
      format,
    );

    final task = DownloadTask(
      id: _uuid.v4(),
      media: media,
      quality: quality,
      format: format,
      savePath: savePath,
      extractAudio: extractAudio,
    );

    state = [...state, task];
    _ensureController(task.id).add(task);
    _run(task);
    return task.id;
  }

  /// Pause a running download.
  void pause(String taskId) {
    final canceler = _cancelers[taskId];
    if (canceler != null && !canceler.isCancelled) {
      canceler.cancel('paused');
    }
    _updateStatus(taskId, DownloadStatus.paused);
  }

  /// Resume a paused/failed download.
  void resume(String taskId) {
    final task = state.firstWhere((t) => t.id == taskId);
    if (task.status == DownloadStatus.paused ||
        task.status == DownloadStatus.failed) {
      _run(task);
    }
  }

  /// Cancel a download entirely and remove it from the queue.
  void cancel(String taskId) {
    final canceler = _cancelers[taskId];
    if (canceler != null && !canceler.isCancelled) {
      canceler.cancel('canceled');
    }
    _updateStatus(taskId, DownloadStatus.canceled);
  }

  /// Retry a failed or canceled download.
  void retry(String taskId) {
    final task = state.firstWhere((t) => t.id == taskId);
    if (task.canRetry) {
      _run(task);
    }
  }

  /// Remove a non-active task from the queue (and from disk optionally).
  Future<void> remove(String taskId, {bool deleteFile = false}) async {
    final task = state.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return;
    if (task.isActive) cancel(taskId);

    if (deleteFile) {
      final file = File(task.savePath);
      if (await file.exists()) await file.delete();
    }

    state = state.where((t) => t.id != taskId).toList();
    final controller = _controllers.remove(taskId);
    await controller?.close();
  }

  // ---------------------------------------------------------------------------
  // Internal: actual HTTP download worker
  // ---------------------------------------------------------------------------

  Future<void> _run(DownloadTask task) async {
    final canceler = CancelToken();
    _cancelers[task.id] = canceler;

    // Reset transient state for the run.
    task
      ..status = DownloadStatus.running
      ..progress = 0
      ..downloadedBytes = 0
      ..totalBytes = 0
      ..error = null
      ..startedAt = DateTime.now()
      ..completedAt = null;

    _emit(task);

    try {
      await _dio.download(
        task.media.streamUrl!,
        task.savePath,
        cancelToken: canceler,
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(seconds: 30),
          followRedirects: true,
          maxRedirects: 5,
        ),
        onReceiveProgress: (received, total) {
          task.downloadedBytes = received;
          task.totalBytes = total;
          task.progress = total > 0 ? received / total : 0;
          _emit(task);
        },
      );

      task
        ..status = DownloadStatus.completed
        ..progress = 1
        ..completedAt = DateTime.now();
      _emit(task);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // status already set by pause()/cancel()
        return;
      }
      task
        ..status = DownloadStatus.failed
        ..error = e.message ?? e.error?.toString() ?? 'Download failed'
        ..completedAt = DateTime.now();
      _emit(task);
    } catch (e) {
      task
        ..status = DownloadStatus.failed
        ..error = e.toString()
        ..completedAt = DateTime.now();
      _emit(task);
    } finally {
      _cancelers.remove(task.id);
    }
  }

  void _updateStatus(String taskId, DownloadStatus status) {
    final task = state.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return;
    task.status = status;
    _emit(task);
  }

  void _emit(DownloadTask task) {
    // Push to the per-task stream + force a rebuild of the queue list.
    _ensureController(task.id).add(task);
    state = [...state];
  }

  StreamController<DownloadTask> _ensureController(String id) {
    return _controllers.putIfAbsent(
      id,
      () => StreamController<DownloadTask>.broadcast(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _cancelers.clear();
    _dio.close(force: true);
    super.dispose();
  }
}

/// Riverpod provider for the download manager.
final downloadManagerProvider =
    StateNotifierProvider<DownloadManager, List<DownloadTask>>((ref) {
  return DownloadManager();
});

/// Convenience: stream of progress for a single task.
final downloadProgressProvider =
    StreamProvider.autoDispose.family<DownloadTask, String>((ref, taskId) {
  final mgr = ref.watch(downloadManagerProvider.notifier);
  return mgr.watch(taskId);
});
