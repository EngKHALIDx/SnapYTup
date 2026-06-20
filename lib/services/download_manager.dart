import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';
import '../models/media_item.dart';

class DownloadManager extends StateNotifier<List<DownloadTask>> {
  DownloadManager() : super([]);
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelers = {};

  Future<Directory> _dir(bool audio) async {
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final sub = audio ? 'Music' : 'Videos';
    final d = Directory(p.join(base.path, 'MediaGrab', sub));
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  String _safeName(String s) => s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  Future<String> enqueue({
    required MediaItem media,
    required String streamUrl,
    required String quality,
    required String format,
    required bool isAudio,
  }) async {
    final dir = await _dir(isAudio);
    final name = _safeName('${media.author ?? ''} ${media.title}'.trim());
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      media: media.copyWith(streamUrl: streamUrl),
      quality: quality,
      format: format,
      savePath: p.join(dir.path, '$name.$format'),
      isAudio: isAudio,
    );
    state = [...state, task];
    _run(task);
    return task.id;
  }

  void pause(String id) {
    _cancelers[id]?.cancel('paused');
    _update(id, (t) => t.state = DownloadState.paused);
  }

  void resume(String id) {
    final t = state.where((e) => e.id == id).firstOrNull;
    if (t != null && (t.state == DownloadState.paused || t.state == DownloadState.failed)) _run(t);
  }

  void cancel(String id) {
    _cancelers[id]?.cancel('canceled');
    _update(id, (t) => t.state = DownloadState.failed);
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void _update(String id, void Function(DownloadTask) fn) {
    final t = state.where((e) => e.id == id).firstOrNull;
    if (t == null) return;
    fn(t);
    state = [...state];
  }

  Future<void> _run(DownloadTask task) async {
    final canceler = CancelToken();
    _cancelers[task.id] = canceler;
    task
      ..state = DownloadState.running
      ..startTime = DateTime.now()
      ..progress = 0
      ..error = null;
    state = [...state];

    try {
      await _dio.download(
        task.media.streamUrl!,
        task.savePath,
        cancelToken: canceler,
        options: Options(receiveTimeout: const Duration(minutes: 30)),
        onReceiveProgress: (received, total) {
          task
            ..downloadedBytes = received
            ..totalBytes = total
            ..progress = total > 0 ? received / total : 0;
          state = [...state];
        },
      );
      task.state = DownloadState.completed;
      task.progress = 1;
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        task.state = DownloadState.failed;
        task.error = e.message ?? 'Download failed';
      }
    } catch (e) {
      task.state = DownloadState.failed;
      task.error = e.toString();
    } finally {
      _cancelers.remove(task.id);
      state = [...state];
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
