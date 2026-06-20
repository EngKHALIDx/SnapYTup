import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Storage cleanup utilities — finds large files, junk cache, WhatsApp
/// backups, etc. that the user may want to delete to free space.
class StorageCleanupService {
  /// Scan common cache locations and return candidate files to delete.
  Future<List<CleanupCandidate>> scanJunk() async {
    final candidates = <CleanupCandidate>[];

    // 1. Android/Android/data/<pkg>/cache — common app caches.
    final androidData = Directory('/storage/emulated/0/Android/data');
    if (androidData.existsSync()) {
      await for (final pkgDir in androidData.list()) {
        if (pkgDir is! Directory) continue;
        final cacheDir = Directory(p.join(pkgDir.path, 'cache'));
        if (cacheDir.existsSync()) {
          await _scanDir(cacheDir, 'App cache · ${p.basename(pkgDir.path)}', candidates);
        }
      }
    }

    // 2. Downloaded WhatsApp backups (`.db.crypt14` etc.)
    final waBackup = Directory('/storage/emulated/0/WhatsApp/Databases');
    if (waBackup.existsSync()) {
      await _scanDir(waBackup, 'WhatsApp backup', candidates);
    }

    // 3. Thumbnails cache.
    final dcimThumbs = Directory('/storage/emulated/0/DCIM/.thumbnails');
    if (dcimThumbs.existsSync()) {
      await _scanDir(dcimThumbs, 'DCIM thumbnails', candidates);
    }

    candidates.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return candidates;
  }

  /// Scan MediaGrab's own downloads folder.
  Future<List<CleanupCandidate>> scanOwnDownloads() async {
    final candidates = <CleanupCandidate>[];
    final dirs = [
      '/storage/emulated/0/Download/MediaGrab/Videos',
      '/storage/emulated/0/Download/MediaGrab/Music',
      '/storage/emulated/0/Download/MediaGrab/WhatsApp',
    ];
    for (final path in dirs) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        await _scanDir(dir, 'MediaGrab · ${p.basename(path)}', candidates);
      }
    }
    candidates.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return candidates;
  }

  Future<void> _scanDir(Directory dir, String label, List<CleanupCandidate> out) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.size < 1024 * 100) continue; // skip files <100KB
        out.add(CleanupCandidate(
          path: entity.path,
          sizeBytes: stat.size,
          modified: stat.modified,
          label: label,
        ));
      }
    } catch (_) {
      // Permission denied etc — skip silently.
    }
  }

  /// Delete a list of files. Returns the number of bytes freed.
  Future<int> delete(List<CleanupCandidate> candidates) async {
    var freed = 0;
    for (final c in candidates) {
      try {
        final f = File(c.path);
        if (await f.exists()) {
          await f.delete();
          freed += c.sizeBytes;
        }
      } catch (_) {
        // ignore
      }
    }
    return freed;
  }
}

class CleanupCandidate {
  const CleanupCandidate({
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.label,
  });

  final String path;
  final int sizeBytes;
  final DateTime modified;
  final String label;
}

/// Riverpod provider.
final storageCleanupProvider = Provider<StorageCleanupService>((ref) {
  return StorageCleanupService();
});
