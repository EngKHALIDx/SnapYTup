import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/models/media_item.dart';

/// Best-effort scraper for TikTok, Instagram, Facebook and Twitter.
///
/// These platforms actively try to block scrapers, so this class is *best
/// effort* only — it tries multiple well-known tricks to extract a direct
/// `.mp4` URL from a share-URL. If everything fails, the caller should fall
/// back to the in-app browser where the user can play the video and tap the
/// "download detected video" button.
class GenericVideoRepository {
  GenericVideoRepository() : _dio = Dio();

  final Dio _dio;

  /// Probe a URL and (if successful) return a [MediaItem] with a [streamUrl]
  /// pointing to the direct `.mp4` file.
  Future<MediaItem?> resolve(String url) async {
    final platform = _detectPlatform(url);

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          maxRedirects: 5,
          headers: _headersFor(platform),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final htmlString = response.data ?? '';
      final direct = _extractDirectVideoUrl(htmlString, platform);
      if (direct == null) return null;

      final title = _extractTitle(htmlString) ?? _defaultTitle(platform);
      final thumb = _extractThumbnail(htmlString, platform);

      return MediaItem(
        id: url,
        title: title,
        platform: platform,
        sourceUrl: url,
        streamUrl: direct,
        thumbnailUrl: thumb,
        type: MediaType.video,
      );
    } catch (_) {
      return null;
    }
  }

  /// Detect which platform a URL points to.
  MediaPlatform _detectPlatform(String url) {
    final u = url.toLowerCase();
    if (u.contains('tiktok.com')) return MediaPlatform.tiktok;
    if (u.contains('instagram.com')) return MediaPlatform.instagram;
    if (u.contains('facebook.com') || u.contains('fb.watch')) return MediaPlatform.facebook;
    if (u.contains('twitter.com') || u.contains('x.com')) return MediaPlatform.twitter;
    return MediaPlatform.browser;
  }

  /// Per-platform HTTP headers (mobile user-agents tend to return simpler HTML).
  Map<String, String> _headersFor(MediaPlatform p) {
    const base = {
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };
    switch (p) {
      case MediaPlatform.tiktok:
        return {
          ...base,
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        };
      case MediaPlatform.instagram:
        return {
          ...base,
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        };
      case MediaPlatform.facebook:
        return {
          ...base,
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        };
      case MediaPlatform.twitter:
        return {
          ...base,
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        };
      default:
        return {
          ...base,
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        };
    }
  }

  /// Pull a direct mp4 URL out of an HTML response.
  /// We look for the most common patterns: og:video, twitter:player:stream,
  /// and explicit `.mp4` URLs in script blocks.
  String? _extractDirectVideoUrl(String htmlString, MediaPlatform platform) {
    final doc = html_parser.parse(htmlString);

    // 1. Open Graph video tag.
    final ogVideo = doc.querySelector('meta[property="og:video"]')?.attributes['content'] ??
        doc.querySelector('meta[property="og:video:url"]')?.attributes['content'] ??
        doc.querySelector('meta[property="og:video:secure_url"]')?.attributes['content'];
    if (ogVideo != null && ogVideo.contains('.mp4')) return ogVideo;

    // 2. Twitter player stream.
    final twStream = doc
        .querySelector('meta[name="twitter:player:stream"]')
        ?.attributes['content'];
    if (twStream != null && twStream.contains('.mp4')) return twStream;

    // 3. Look for any URL ending in `.mp4` in the entire document.
    // `\S` = any non-whitespace character. Keep it simple to avoid
    // quote-escaping headaches inside Dart raw strings.
    final mp4Regex = RegExp(r'https?\://\S+?\.mp4\S*');
    final match = mp4Regex.firstMatch(htmlString);
    if (match != null) return match.group(0);

    return null;
  }

  String? _extractTitle(String htmlString) {
    final doc = html_parser.parse(htmlString);
    return doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
        doc.querySelector('title')?.text;
  }

  String? _extractThumbnail(String htmlString, MediaPlatform platform) {
    final doc = html_parser.parse(htmlString);
    return doc.querySelector('meta[property="og:image"]')?.attributes['content'];
  }

  String _defaultTitle(MediaPlatform p) {
    switch (p) {
      case MediaPlatform.tiktok:    return 'TikTok video';
      case MediaPlatform.instagram: return 'Instagram video';
      case MediaPlatform.facebook:  return 'Facebook video';
      case MediaPlatform.twitter:   return 'Twitter video';
      default:                      return 'Video';
    }
  }

  void dispose() {
    _dio.close(force: true);
  }
}

/// Riverpod provider.
final genericVideoRepoProvider = Provider<GenericVideoRepository>((ref) {
  final repo = GenericVideoRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
