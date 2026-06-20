import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/media_item.dart';

/// Ultimate YouTube downloader with **8 different strategies** to bypass
/// all known YouTube restrictions.
///
/// Each strategy uses a different User-Agent + client identity + headers,
/// so YouTube sees eight different "clients" for the same video. On a
/// residential IP (real phone), at least one of these almost always succeeds.
class YouTubeService {
  YouTubeService() : _yt = yt.YoutubeExplode();
  final yt.YoutubeExplode _yt;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 15),
    followRedirects: true,
    maxRedirects: 5,
  ));

  static const _apiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';

  Future<List<MediaItem>> search(String query, {int limit = 20}) async {
    try {
      final results = (await _yt.search.search(query)).take(limit).toList();
      return results.map(_toMediaItem).whereType<MediaItem>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Get available quality options. Tries all 8 strategies in order.
  Future<List<QualityOption>> getQualities(String videoId) async {
    final strategies = <Future<List<QualityOption>>>[
      _tryExplode(videoId),
      _tryInnerTube(videoId, clientName: 'WEB', clientVersion: '2.20240101.00.00', userAgent: _uaWeb),
      _tryInnerTube(videoId, clientName: 'ANDROID_VR', clientVersion: '1.57', userAgent: _uaAndroidVr),
      _tryInnerTube(videoId, clientName: 'IOS', clientVersion: '19.09.3', userAgent: _uaIos),
      _tryInnerTube(videoId, clientName: 'MWEB', clientVersion: '2.20240101.01.00', userAgent: _uaMweb),
      _tryInnerTube(videoId, clientName: 'WEB_EMBEDDED_PLAYER', clientVersion: '1.20240101.00.00', userAgent: _uaWeb, extraBody: {'thirdParty': {'embedUrl': 'https://www.google.com'}}),
      _tryInnerTube(videoId, clientName: 'ANDROID', clientVersion: '19.09.37', userAgent: _uaAndroid),
      _tryInnerTube(videoId, clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', clientVersion: '2.0', userAgent: _uaTv, extraBody: {'thirdParty': {'embedUrl': 'https://www.youtube.com'}}),
    ];

    for (final strategy in strategies) {
      try {
        final result = await strategy;
        if (result.isNotEmpty) return result;
      } catch (_) {}
    }
    return [];
  }

  static const _uaWeb = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const _uaAndroidVr = 'com.google.android.apps.youtube.vr.oculus/1.57 (Linux; U; Android 12; GB) gzip';
  static const _uaIos = 'com.google.ios.youtube/19.09.3 (iPhone14,3; U; CPU iOS 15_6 like Mac OS X)';
  static const _uaMweb = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  static const _uaAndroid = 'com.google.android.youtube/19.09.37 (Linux; U; Android 13; Pixel 7) gzip';
  static const _uaTv = 'Mozilla/5.0 (PlayStation; PlayStation 4/9.00) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15';

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

  Future<List<QualityOption>> _tryInnerTube(
    String videoId, {
    required String clientName,
    required String clientVersion,
    required String userAgent,
    Map<String, dynamic>? extraBody,
  }) async {
    try {
      final visitorId = 'Cgt${_randomString(20)}';

      final body = <String, dynamic>{
        'videoId': videoId,
        'context': {
          'client': {
            'clientName': clientName,
            'clientVersion': clientVersion,
            'hl': 'en',
            'gl': 'US',
            'visitorData': visitorId,
          }
        }
      };
      if (extraBody != null) body.addAll(extraBody);

      final response = await _dio.post<String>(
        'https://www.youtube.com/youtubei/v1/player?key=$_apiKey&prettyPrint=false',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': userAgent,
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Origin': 'https://www.youtube.com',
            'Referer': 'https://www.youtube.com/watch?v=$videoId',
            'X-YouTube-Client-Name': _clientNameId(clientName).toString(),
            'X-YouTube-Client-Version': clientVersion,
          },
        ),
        data: jsonEncode(body),
      );

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final streamingData = data['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) return [];

      final options = <QualityOption>[];

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

  int _clientNameId(String name) => switch (name) {
        'WEB' => 1,
        'ANDROID' => 3,
        'IOS' => 5,
        'MWEB' => 2,
        'ANDROID_VR' => 28,
        'WEB_EMBEDDED_PLAYER' => 56,
        'TVHTML5_SIMPLY_EMBEDDED_PLAYER' => 85,
        _ => 1,
      };

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String? _extractUrl(dynamic format) {
    if (format is! Map) return null;
    final url = format['url'];
    if (url is String && url.isNotEmpty) return url;
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
