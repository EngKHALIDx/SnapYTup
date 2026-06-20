import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches lyrics for a song from the free lyrics.ovh API.
/// Snaptube offers built-in lyrics display alongside downloaded music.
class LyricsService {
  /// Returns lyrics text for [artist] + [title], or null if not found.
  Future<String?> fetchLyrics({required String artist, required String title}) async {
    if (artist.isEmpty || title.isEmpty) return null;
    try {
      final client = HttpClient();
      final cleanArtist = Uri.encodeComponent(artist.split(' - ').first.trim());
      final cleanTitle = Uri.encodeComponent(
          title.split(RegExp(r'[\(\[]')).first.trim());
      final url = Uri.parse('https://api.lyrics.ovh/v1/$cleanArtist/$cleanTitle');
      final req = await client.getUrl(url);
      final res = await req.close();
      if (res.statusCode != 200) {
        client.close();
        return null;
      }
      final body = await res.transform(utf8.decoder).join();
      client.close();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final lyrics = data['lyrics'] as String?;
      return lyrics?.trim().isEmpty == true ? null : lyrics?.trim();
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider.
final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService();
});

/// Async family provider for the lyrics of a specific (artist, title).
final lyricsForProvider =
    FutureProvider.family<String?, ({String artist, String title})>((ref, args) {
  return ref.watch(lyricsServiceProvider).fetchLyrics(
        artist: args.artist,
        title: args.title,
      );
});
