import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../../core/models/media_item.dart';

/// Wraps [youtube_explode_dart] to expose a small surface that the rest of
/// the app uses (search, get manifest, get stream URL).
class YouTubeRepository {
  YouTubeRepository() : _yt = yt.YoutubeExplode();

  final yt.YoutubeExplode _yt;

  /// Search YouTube and return up to [limit] results.
  Future<List<MediaItem>> search(String query, {int limit = 25}) async {
    final results = (await _yt.search.search(query)).take(limit).toList();
    return results.map(_toMediaItem).toList();
  }

  /// Fetch available video stream info for a video id.
  /// Returns a list of [StreamQualityOption] sorted highest-quality first.
  Future<List<StreamQualityOption>> getQualities(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    final muxed = manifest.muxed
        .map((s) => StreamQualityOption(
              label: s.videoQuality.qualityString,
              container: s.container.name,
              sizeBytes: s.size.totalBytes,
              url: s.url.toString(),
              isAudioOnly: false,
            ))
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    final audio = manifest.audioOnly
        .map((s) => StreamQualityOption(
              label: 'Audio ${s.bitrate}',
              container: s.container.name,
              sizeBytes: s.size.totalBytes,
              url: s.url.toString(),
              isAudioOnly: true,
            ))
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    return [...muxed, ...audio];
  }

  /// Resolve the direct stream URL for the given video id & quality label.
  /// If [audioOnly] is true, returns the highest-bitrate audio stream.
  Future<String> resolveStreamUrl(
    String videoId, {
    String? qualityLabel,
    bool audioOnly = false,
  }) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    if (audioOnly) {
      final best = manifest.audioOnly.withHighestBitrate();
      return best.url.toString();
    }

    if (qualityLabel == null) {
      final best = manifest.muxed.withHighestBitrate();
      return best.url.toString();
    }

    // Try to find a muxed stream matching the requested quality.
    final candidates = manifest.muxed
        .where((s) => s.videoQuality.qualityString == qualityLabel)
        .toList();
    if (candidates.isEmpty) {
      final best = manifest.muxed.withHighestBitrate();
      return best.url.toString();
    }
    return candidates.first.url.toString();
  }

  /// Get a single video's metadata by id or URL.
  Future<MediaItem> getVideo(String idOrUrl) async {
    final video = await _yt.videos.get(idOrUrl);
    return _toMediaItem(video);
  }

  /// Convert a yt_explode [Video] into a [MediaItem].
  MediaItem _toMediaItem(yt.Video v) {
    return MediaItem(
      id: v.id.value,
      title: v.title,
      platform: MediaPlatform.youtube,
      sourceUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
      thumbnailUrl: v.thumbnails.highResUrl,
      duration: v.duration,
      author: v.author,
      uploadDate: v.uploadDate,
      viewCount: v.engagement.viewCount,
      description: v.description,
    );
  }

  void dispose() {
    _yt.close();
  }
}

/// Selectable quality option returned by [YouTubeRepository.getQualities].
class StreamQualityOption {
  const StreamQualityOption({
    required this.label,
    required this.container,
    required this.sizeBytes,
    required this.url,
    required this.isAudioOnly,
  });

  final String label;
  final String container;
  final int sizeBytes;
  final String url;
  final bool isAudioOnly;

  @override
  String toString() => isAudioOnly
      ? '$label (.$container)'
      : '$label (.$container)';
}

/// Riverpod provider.
final youTubeRepoProvider = Provider<YouTubeRepository>((ref) {
  final repo = YouTubeRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
