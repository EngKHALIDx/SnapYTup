import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

class LibraryService {
  /// Asynchronously list files in the library folder.
  ///
  /// FIX: previously used `dir.listSync()` which blocks the UI thread.
  /// Now uses async `dir.list()` so the UI doesn't freeze on large libraries.
  /// FIX: sort order was Z→A (reversed); now A→Z as users expect.
  Future<List<MediaItem>> list({bool audio = false}) async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final sub = audio ? 'Music' : 'Videos';
    final dir = Directory(p.join(base.path, 'MediaGrab', sub));
    if (!dir.existsSync()) return [];
    final exts = audio ? ['.mp3', '.m4a', '.aac', '.wav'] : ['.mp4', '.webm', '.mkv'];

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();
      if (!exts.any((e) => lower.endsWith(e))) continue;
      files.add(entity);
    }

    final items = files.map((f) {
      final name = p.basenameWithoutExtension(f.path);
      return MediaItem(
        id: f.path,
        title: name,
        platform: Platform.unknown,
        sourceUrl: f.path,
        streamUrl: f.path,
      );
    }).toList()
      // Sort A→Z (was reversed Z→A before).
      ..sort((a, b) => a.title.compareTo(b.title));

    return items;
  }
}

final videosProvider = FutureProvider<List<MediaItem>>((ref) async {
  return LibraryService().list(audio: false);
});

final musicProvider = FutureProvider<List<MediaItem>>((ref) async {
  return LibraryService().list(audio: true);
});
