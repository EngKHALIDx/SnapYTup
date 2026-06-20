import 'media_item.dart';

enum DownloadState { queued, running, paused, completed, failed }

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.media,
    required this.quality,
    required this.format,
    required this.savePath,
    required this.isAudio,
  });

  final String id;
  final MediaItem media;
  final String quality;
  final String format;
  final String savePath;
  final bool isAudio;

  DownloadState state = DownloadState.queued;
  double progress = 0;
  int downloadedBytes = 0;
  int totalBytes = 0;
  String? error;
  DateTime? startTime;

  bool get isActive => state == DownloadState.queued || state == DownloadState.running;
  bool get canRetry => state == DownloadState.failed;
  int? get speedBps {
    final s = startTime;
    if (s == null) return null;
    final elapsed = DateTime.now().difference(s).inSeconds;
    return elapsed > 0 ? downloadedBytes ~/ elapsed : null;
  }
}
