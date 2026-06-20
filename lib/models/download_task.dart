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
  /// Mutable so we can refresh the stream URL when it expires (403).
  MediaItem media;
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
  DateTime? endTime;

  bool get isActive => state == DownloadState.queued || state == DownloadState.running;
  bool get canRetry => state == DownloadState.failed;
  bool get isCompleted => state == DownloadState.completed;

  /// Speed in bytes/sec (null if unknown).
  int? get speedBps {
    final s = startTime;
    if (s == null) return null;
    final elapsed = DateTime.now().difference(s).inSeconds;
    if (elapsed <= 0) return null;
    return downloadedBytes ~/ elapsed;
  }

  /// ETA in seconds (null if unknown).
  int? get etaSeconds {
    if (progress <= 0 || speedBps == null || speedBps == 0) return null;
    final remaining = (totalBytes - downloadedBytes);
    return remaining ~/ speedBps!;
  }

  /// Formatted size string e.g. "1.2 MB".
  String get sizeText {
    if (totalBytes <= 0) return '';
    return _fmt(totalBytes);
  }

  /// Formatted speed string e.g. "1.2 MB/s".
  String get speedText {
    final s = speedBps;
    if (s == null || s <= 0) return '';
    return '${_fmt(s)}/s';
  }

  static String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
