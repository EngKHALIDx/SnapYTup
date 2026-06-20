import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../models/media_item.dart';
import '../utils/storage_utils.dart';

/// Converts a downloaded video file into an audio-only file. Snaptube
/// offers this as "Convert to MP3" inside the Library screen.
///
/// The MVP implementation does **byte-level copy + rename** to .mp3 / .m4a
/// only — it doesn't re-encode the audio. For proper transcoding you'd
/// need ffmpeg_kit_flutter (heavy native dep — see notes in pubspec.yaml).
///
/// What works today:
///   - If the source video already contains an audio stream, we just copy
///     the file and rename it. Most Android music players will detect the
///     real container automatically.
///   - The output is written to MediaGrab/Music/<title>.mp3 so it shows
///     up in the Music tab.
class Mp3ConverterService {
  /// Convert [videoPath] to an MP3 file inside MediaGrab/Music.
  /// Returns the absolute path of the new audio file, or null on failure.
  Future<String?> convertToMp3(String videoPath, {String? title}) async {
    try {
      final src = File(videoPath);
      if (!await src.exists()) return null;
      final musicDir = await StorageUtils.musicDir();
      final name = StorageUtils.sanitizeFileName(
          title ?? p.basenameWithoutExtension(videoPath));
      final dest = p.join(musicDir.path, '$name.mp3');
      await src.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: convert a [MediaItem] (whose sourceUrl is a local file).
  Future<String?> convertMediaItemToMp3(MediaItem item) {
    return convertToMp3(item.sourceUrl, title: item.title);
  }

  /// Estimated output file size — for MVP we assume the audio portion is
  /// ~5% of the video size (rough heuristic, real value depends on bitrate).
  int? estimateMp3Size(int? videoSizeBytes) {
    if (videoSizeBytes == null) return null;
    return (videoSizeBytes * 0.05).round();
  }
}

/// Riverpod provider.
final mp3ConverterProvider = Provider<Mp3ConverterService>((ref) {
  return Mp3ConverterService();
});
