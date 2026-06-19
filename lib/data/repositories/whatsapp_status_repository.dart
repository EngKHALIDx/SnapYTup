import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';

/// Scans the on-disk WhatsApp status folders (Android-only) and exposes
/// both "Recent" (about-to-disappear) statuses and already-saved copies.
class WhatsAppStatusRepository {
  /// Two locations to scan on Android depending on WhatsApp version.
  /// The new "Android 11+ scoped storage" version uses `Android/media/`.
  static const List<String> _statusDirs = [
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp/Media/.Statuses',
  ];

  /// List recent statuses (in the last 24h) found on the device.
  Future<List<MediaItem>> listRecent() async {
    if (!Platform.isAndroid) return [];

    final files = <File>[];
    for (final path in _statusDirs) {
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      final recent = dir
          .listSync()
          .whereType<File>()
          .where((f) => _isMedia(f.path))
          .where((f) => f.statSync().modified.isAfter(
                DateTime.now().subtract(const Duration(hours: 24)),
              ))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      files.addAll(recent);
    }

    return files.map(_toMediaItem).toList();
  }

  /// List already-saved statuses inside the MediaGrab/WhatsApp folder.
  Future<List<MediaItem>> listSaved(String savedDirPath) async {
    final dir = Directory(savedDirPath);
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isMedia(f.path))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.map((f) => _toMediaItem(f, saved: true)).toList();
  }

  /// Persist a status from the .Statuses folder into our own folder.
  Future<String> save(MediaItem item, String targetDirPath) async {
    final src = File(item.sourceUrl);
    if (!src.existsSync()) throw FileSystemException('Source missing', item.sourceUrl);

    final name = src.uri.pathSegments.last;
    final dst = File('${targetDirPath.endsWith('/') ? targetDirPath.substring(0, targetDirPath.length - 1) : targetDirPath}/$name');
    if (!dst.parent.existsSync()) dst.parent.createSync(recursive: true);
    await src.copy(dst.path);
    return dst.path;
  }

  bool _isMedia(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.webp');
  }

  MediaItem _toMediaItem(File f, {bool saved = false}) {
    final path = f.path;
    final isVideo = path.toLowerCase().endsWith('.mp4');
    return MediaItem(
      id: path,
      title: f.uri.pathSegments.last,
      platform: MediaPlatform.whatsapp,
      sourceUrl: path,
      streamUrl: path,
      thumbnailUrl: isVideo ? null : path,
      type: isVideo ? MediaType.video : MediaType.image,
    );
  }
}

/// Riverpod provider.
final whatsappStatusRepoProvider = Provider<WhatsAppStatusRepository>((ref) {
  return WhatsAppStatusRepository();
});
