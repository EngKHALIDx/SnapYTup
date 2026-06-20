import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/media_item.dart';

/// Multi-strategy YouTube downloader.
///
/// Tries three strategies in order, picking the first that yields a valid
/// stream URL:
///
/// 1. **youtube_explode_dart** — fast, no setup, but fails on videos with
///    signatureCipher that the library can't decrypt.
/// 2. **InnerTube WEB client** — direct HTTP call to YouTube's internal API
///    using browser User-Agent. Sometimes returns direct URLs that
///    youtube_explode misses.
/// 3. **InnerTube ANDROID_VR client** — known to bypass signatureCipher on
///    a wider range of videos (this is the algorithm yt-dlp uses).
///
/// If all three fail, returns an empty list (the UI shows "no qualities").
/// Users can retry later — YouTube rotates which clients are blocked.
class YouTubeService {
  YouTubeService() : _yt = yt.YoutubeExplode();
  final yt.YoutubeExplode _yt;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 15),
  ));

  Future<List<MediaItem>> search(String query, {int limit = 20}) async {
    try {
      final results = (await _yt.search.search(query)).take(limit).toList();
      return results.map(_toMediaItem).whereType<MediaItem>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Get available quality options, trying all three strategies.
  Future<List<QualityOption>> getQualities(String videoId) async {
    // Strategy 1: youtube_explode_dart
    var options = await _tryExplode(videoId);
    if (options.isNotEmpty) return options;

    // Strategy 2: InnerTube WEB client
    options = await _tryInnerTube(
      videoId,
      clientName: 'WEB',
      clientVersion: '2.20240101.00.00',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );
    if (options.isNotEmpty) return options;

    // Strategy 3: InnerTube ANDROID_VR client (best at bypassing signatures)
    options = await _tryInnerTube(
      videoId,
      clientName: 'ANDROID_VR',
      clientVersion: '1.57',
      userAgent: 'com.google.android.apps.youtube.vr.oculus/1.57 (Linux; U; Android 12; GB) gzip',
    );
    if (options.isNotEmpty) return options;

    // Strategy 4: InnerTube IOS (sometimes works when others don't)
    options = await _tryInnerTube(
      videoId,
      clientName: 'IOS',
      clientVersion: '19.09.3',
      userAgent: 'com.google.ios.youtube/19.09.3 (iPhone14,3; U; CPU iOS 15_6 like Mac OS X)',
    );
    if (options.isNotEmpty) return options;

    // Strategy 5: InnerTube MWEB (mobile web — least likely to be blocked)
    options = await _tryInnerTube(
      videoId,
      clientName: 'MWEB',
      clientVersion: '2.20240101.01.00',
      userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    );
    if (options.isNotEmpty) return options;

    // Strategy 6: InnerTube WEB_EMBEDDED_PLAYER (used for iframe embeds)
    options = await _tryInnerTube(
      videoId,
      clientName: 'WEB_EMBEDDED_PLAYER',
      clientVersion: '1.20240101.00.00',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      extraBody: {'thirdParty': {'embedUrl': 'https://www.google.com'}},
    );

    return options;
  }

  /// Strategy 1: youtube_explode_dart
  Future<List<QualityOption>> _tryExplode(String videoId) async {
    yt.StreamManifest manifest;
    try {
      manifest = await _yt.videos.streamsClient.getManifest(videoId);
    } catch (_) {
      return [];
    }

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

  /// Strategy 2-6: InnerTube API with various client identities
  Future<List<QualityOption>> _tryInnerTube(
    String videoId, {
    required String clientName,
    required String clientVersion,
    required String userAgent,
    Map<String, dynamic>? extraBody,
  }) async {
    try {
      final body = <String, dynamic>{
        'videoId': videoId,
        'context': {
          'client': {
            'clientName': clientName,
            'clientVersion': clientVersion,
            'hl': 'en',
            'gl': 'US',
          }
        }
      };
      if (extraBody != null) body.addAll(extraBody);

      final response = await _dio.post<String>(
        'https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': userAgent,
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Origin': 'https://www.youtube.com',
            'Referer': 'https://www.youtube.com/watch?v=$videoId',
          },
        ),
        data: jsonEncode(body),
      );

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final streamingData = data['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) return [];

      final options = <QualityOption>[];

      // Muxed formats (combined video + audio)
      final formats = streamingData['formats'] as List<dynamic>? ?? [];
      for (final f in formats) {
        final url = _extractUrl(f);
        if (url == null) continue;
        final qualityLabel = (f['qualityLabel'] ?? '?').toString();
        final mimeType = (f['mimeType'] ?? '').toString();
        final container = mimeType.contains('mp4') ? 'mp4' : 'webm';
        final size = int.tryParse((f['contentLength'] ?? '0').toString()) ?? 0;
        options.add(QualityOption(
          label: qualityLabel,
          sizeBytes: size,
          url: url,
          isAudio: false,
          container: container,
        ));
      }
      options.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

      // Adaptive audio-only formats
      final adaptive = streamingData['adaptiveFormats'] as List<dynamic>? ?? [];
      final audioOpts = <QualityOption>[];
      for (final f in adaptive) {
        final mimeType = (f['mimeType'] ?? '').toString();
        if (!mimeType.startsWith('audio/')) continue;
        final url = _extractUrl(f);
        if (url == null) continue;
        final bitrate = (f['bitrate'] ?? 0);
        final size = int.tryParse((f['contentLength'] ?? '0').toString()) ?? 0;
        audioOpts.add(QualityOption(
          label: '${(bitrate / 1000).round()} kbps',
          sizeBytes: size,
          url: url,
          isAudio: true,
          container: mimeType.contains('mp4') ? 'm4a' : 'webm',
        ));
      }
      audioOpts.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

      return [...options, ...audioOpts];
    } catch (_) {
      return [];
    }
  }

  /// Extract a usable URL from an InnerTube format object.
  /// Some formats have a direct 'url', others have 'signatureCipher' which
  /// we cannot decrypt client-side (would need the YouTube JS player). We
  /// skip those — they're the cause of the original "Null" crash.
  String? _extractUrl(dynamic format) {
    if (format is! Map) return null;
    final url = format['url'];
    if (url is String && url.isNotEmpty) return url;
    // signatureCipher requires JS interpretation — skip.
    return null;
  }

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

  void dispose() {
    _yt.close();
    _dio.close(force: true);
  }
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
