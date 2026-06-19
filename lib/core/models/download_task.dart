import 'media_item.dart';

/// Lifecycle states of a download.
enum DownloadStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  canceled,
}

/// A single entry in the download queue.
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.media,
    required this.quality,
    required this.format,
    required this.savePath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.startedAt,
    this.completedAt,
    this.extractAudio = false,
  });

  /// Unique id (UUID4 by default).
  final String id;

  /// The media we are downloading.
  final MediaItem media;

  /// Requested quality, e.g. "720p", "1080p", "audio".
  final String quality;

  /// Output container, e.g. "mp4", "mp3", "m4a".
  final String format;

  /// Absolute path where the file will be written.
  final String savePath;

  /// Current status (mutable through controller).
  DownloadStatus status;

  /// Progress fraction in `[0, 1]`.
  double progress;

  /// Bytes downloaded so far.
  int downloadedBytes;

  /// Total bytes (may be 0 until server reports Content-Length).
  int totalBytes;

  /// Last failure reason, if any.
  String? error;

  /// When the download started.
  DateTime? startedAt;

  /// When the download completed (success or failure).
  DateTime? completedAt;

  /// Whether to extract audio-only (instead of full video).
  final bool extractAudio;

  /// Convenience: how many seconds the download has been running so far.
  Duration? get elapsed =>
      startedAt == null ? null : (completedAt ?? DateTime.now()).difference(startedAt!);

  /// Convenience: human readable ETA in seconds (null when unknown).
  int? get etaSeconds {
    if (progress <= 0 || totalBytes <= 0) return null;
    final elapsedSec = elapsed?.inSeconds ?? 0;
    if (elapsedSec == 0) return null;
    final remainingFraction = 1 - progress;
    return (elapsedSec * remainingFraction / progress).round();
  }

  /// Convenience: bytes-per-second download rate (null when unknown).
  int? get bytesPerSecond {
    final elapsedSec = elapsed?.inSeconds ?? 0;
    if (elapsedSec == 0) return null;
    return downloadedBytes ~/ elapsedSec;
  }

  /// Whether the task is in any of the "active" states.
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.running;

  /// Whether the task can be retried.
  bool get canRetry => status == DownloadStatus.failed || status == DownloadStatus.canceled;
}
