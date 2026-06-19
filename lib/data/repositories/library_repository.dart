import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/utils/storage_utils.dart';

/// Scans the local MediaGrab/Videos and MediaGrab/Music directories and
/// exposes the saved files as [MediaItem] lists for the Library tab.
class LibraryRepository {
  Future<List<MediaItem>> listVideos() async {
    final dir = await StorageUtils.videosDir();
    return _scan(dir, MediaType.video, ['.mp4', '.webm', '.mkv']);
  }

  Future<List<MediaItem>> listMusic() async {
    final dir = await StorageUtils.musicDir();
    return _scan(dir, MediaType.audio, ['.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg']);
  }

  Future<List<MediaItem>> listWhatsApp() async {
    final dir = await StorageUtils.whatsappDir();
    return _scan(dir, MediaType.video, ['.mp4', '.jpg', '.jpeg', '.png', '.webp']);
  }

  Future<List<MediaItem>> listAllDownloads() async {
    return [...await listVideos(), ...await listMusic(), ...await listWhatsApp()];
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<int> totalSizeBytes() async {
    final all = await listAllDownloads();
    var total = 0;
    for (final item in all) {
      final f = File(item.sourceUrl);
      if (await f.exists()) total += await f.length();
    }
    return total;
  }

  List<MediaItem> _scan(Directory dir, MediaType type, List<String> extensions) {
    if (!dir.existsSync()) return [];
    final files = dir.listSync().whereType<File>().where((f) {
      final lower = f.path.toLowerCase();
      return extensions.any((ext) => lower.endsWith(ext));
    }).toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.map((f) {
      final isVideo = f.path.toLowerCase().endsWith('.mp4') ||
          f.path.toLowerCase().endsWith('.webm') ||
          f.path.toLowerCase().endsWith('.mkv');
      return MediaItem(
        id: f.path,
        title: f.uri.pathSegments.last,
        platform: MediaPlatform.unknown,
        sourceUrl: f.path,
        streamUrl: f.path,
        type: isVideo ? MediaType.video : type,
        fileSizeBytes: f.statSync().size,
      );
    }).toList();
  }
}

/// Riverpod provider.
final libraryRepoProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

/// Async providers for the UI.
final videosProvider = FutureProvider<List<MediaItem>>((ref) async {
  return ref.watch(libraryRepoProvider).listVideos();
});

final musicProvider = FutureProvider<List<MediaItem>>((ref) async {
  return ref.watch(libraryRepoProvider).listMusic();
});

final downloadsSizeProvider = FutureProvider<int>((ref) async {
  return ref.watch(libraryRepoProvider).totalSizeBytes();
});
