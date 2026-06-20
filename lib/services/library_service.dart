import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

class LibraryService {
  Future<List<MediaItem>> list({bool audio = false}) async {
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final sub = audio ? 'Music' : 'Videos';
    final dir = Directory(p.join(base.path, 'MediaGrab', sub));
    if (!dir.existsSync()) return [];
    final exts = audio ? ['.mp3', '.m4a', '.aac', '.wav'] : ['.mp4', '.webm', '.mkv'];
    return dir.listSync().whereType<File>().where((f) {
      final lower = f.path.toLowerCase();
      return exts.any((e) => lower.endsWith(e));
    }).map((f) {
      final name = p.basenameWithoutExtension(f.path);
      return MediaItem(
        id: f.path,
        title: name,
        platform: Platform.unknown,
        sourceUrl: f.path,
        streamUrl: f.path,
      );
    }).toList()
      ..sort((a, b) => b.title.compareTo(a.title));
  }
}

final videosProvider = FutureProvider<List<MediaItem>>((ref) async {
  return LibraryService().list(audio: false);
});

final musicProvider = FutureProvider<List<MediaItem>>((ref) async {
  return LibraryService().list(audio: true);
});
