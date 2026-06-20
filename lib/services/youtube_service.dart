import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/media_item.dart';

class YouTubeService {
  YouTubeService() : _yt = yt.YoutubeExplode();
  final yt.YoutubeExplode _yt;

  Future<List<MediaItem>> search(String query, {int limit = 20}) async {
    final results = (await _yt.search.search(query)).take(limit).toList();
    return results
        .map((v) => MediaItem(
              id: v.id.value,
              title: v.title,
              platform: Platform.youtube,
              sourceUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
              thumbnailUrl: v.thumbnails.highResUrl,
              duration: v.duration,
              author: v.author,
              viewCount: v.engagement.viewCount,
            ))
        .toList();
  }

  Future<List<QualityOption>> getQualities(String videoId) async {
    final m = await _yt.videos.streamsClient.getManifest(videoId);
    final muxed = m.muxed
        .map((s) => QualityOption(
              label: s.videoQuality.qualityString,
              sizeBytes: s.size.totalBytes,
              url: s.url.toString(),
              isAudio: false,
              container: 'mp4',
            ))
        .toList();
    final audio = m.audioOnly
        .map((s) => QualityOption(
              label: '${s.bitrate}',
              sizeBytes: s.size.totalBytes,
              url: s.url.toString(),
              isAudio: true,
              container: 'm4a',
            ))
        .toList();
    return [...muxed, ...audio];
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
