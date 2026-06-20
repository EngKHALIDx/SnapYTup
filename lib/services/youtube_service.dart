import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/media_item.dart';

/// Wrapper around youtube_explode_dart with defensive handling for the
/// 'Null is not a subtype of type "Uri"' error that happens when YouTube
/// returns a stream manifest with broken/null URL fields.
class YouTubeService {
  YouTubeService() : _yt = yt.YoutubeExplode();
  final yt.YoutubeExplode _yt;

  Future<List<MediaItem>> search(String query, {int limit = 20}) async {
    try {
      final results = (await _yt.search.search(query)).take(limit).toList();
      return results.map(_toMediaItem).whereType<MediaItem>().toList();
    } catch (_) {
      // Search failures should not crash the UI — return empty list.
      return [];
    }
  }

  /// Get available quality options for a YouTube video.
  /// Filters out any stream whose URL is null/empty (the cause of the
  /// 'Null is not a subtype of type "Uri"' error).
  Future<List<QualityOption>> getQualities(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    final muxed = <QualityOption>[];
    for (final s in manifest.muxed) {
      final url = _safeUrl(s.url);
      if (url == null) continue;
      muxed.add(QualityOption(
        label: s.videoQuality.qualityString,
        sizeBytes: s.size.totalBytes,
        url: url,
        isAudio: false,
        container: 'mp4',
      ));
    }
    muxed.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    final audio = <QualityOption>[];
    for (final s in manifest.audioOnly) {
      final url = _safeUrl(s.url);
      if (url == null) continue;
      audio.add(QualityOption(
        label: s.bitrate.toString(),
        sizeBytes: s.size.totalBytes,
        url: url,
        isAudio: true,
        container: 'm4a',
      ));
    }
    audio.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return [...muxed, ...audio];
  }

  /// Convert a youtube_explode Uri to a String, returning null if the Uri
  /// is somehow null or has an empty string representation.
  /// Wrapped in try/catch because some streams return null at runtime even
  /// though the type signature says non-nullable (the cause of
  /// "type 'Null' is not a subtype of type 'Uri'" errors).
  String? _safeUrl(dynamic uri) {
    try {
      if (uri == null) return null;
      final s = uri.toString();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  MediaItem? _toMediaItem(yt.Video v) {
    try {
      return MediaItem(
        id: v.id.value,
        title: v.title,
        platform: Platform.youtube,
        sourceUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
        thumbnailUrl: v.thumbnails.highResUrl,
        duration: v.duration,
        author: v.author,
        viewCount: v.engagement.viewCount,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() => _yt.close();
}

class QualityOption {
  const QualityOption({
    required this.label,
    required this.sizeBytes,
    required this.url,
    required this.isAudio,
    required this.container,
  });
  final String label;
  final int sizeBytes;
  final String url;
  final bool isAudio;
  final String container;
}
