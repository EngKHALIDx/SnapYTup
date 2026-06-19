import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Helpers around storage permissions and the on-disk download layout.
class StorageUtils {
  StorageUtils._();

  /// Request the appropriate storage permission for the running Android
  /// version. Returns `true` if we can proceed with writing files.
  static Future<bool> ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Android 13+ uses granular media permissions.
    if (sdkInt >= 33) {
      final video = await Permission.videos.request();
      final audio = await Permission.audio.request();
      final images = await Permission.photos.request();
      return video.isGranted || audio.isGranted || images.isGranted;
    }

    // Android 10–12 uses READ_EXTERNAL_STORAGE.
    if (sdkInt >= 29) {
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    // Android 9 and below uses the legacy WRITE_EXTERNAL_STORAGE.
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  /// Open the Android "manage all files" settings page (Android 11+).
  /// Useful when the user wants to save outside the app sandbox.
  static Future<bool> openManageAllFilesSettings() {
    return openAppSettings();
  }

  /// Root directory where MediaGrab stores all downloads.
  ///
  /// Strategy:
  /// - Android: app-specific external storage (`Android/data/<pkg>/files`),
  ///   which works without MANAGE_EXTERNAL_STORAGE on Android 10+ and is also
  ///   visible to file managers under that path.
  /// - Other platforms: the user's documents directory.
  static Future<Directory> downloadsRoot() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    } else if (Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      base = await getApplicationDocumentsDirectory();
    }
    base ??= await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'MediaGrab'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Sub-folder for video downloads.
  static Future<Directory> videosDir() async {
    final root = await downloadsRoot();
    final dir = Directory(p.join(root.path, 'Videos'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Sub-folder for audio downloads.
  static Future<Directory> musicDir() async {
    final root = await downloadsRoot();
    final dir = Directory(p.join(root.path, 'Music'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Sub-folder for WhatsApp status saves.
  static Future<Directory> whatsappDir() async {
    final root = await downloadsRoot();
    final dir = Directory(p.join(root.path, 'WhatsApp'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Sanitize a string so it can be safely used as a file name.
  static String sanitizeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'media' : cleaned;
  }

  /// Build a safe file path inside [dir] with the given [title] and [ext].
  static String buildPath(Directory dir, String title, String ext) {
    final safe = sanitizeFileName(title);
    return p.join(dir.path, '$safe.$ext');
  }
}
