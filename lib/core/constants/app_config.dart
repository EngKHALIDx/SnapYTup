/// App-wide constants for MediaGrab.
class AppConfig {
  AppConfig._();

  /// App display name (change here to rebrand).
  static const String appName = 'MediaGrab';

  /// Internal package id kept from upstream SnapYT — change if you fork.
  static const String packageName = 'com.gokei.yt_download';

  /// App version (mirrors pubspec.yaml).
  static const String version = '2.0.0';
  static const int buildNumber = 1;

  /// Default download sub-folders (under the user-visible Downloads dir).
  static const String videosFolder = 'MediaGrab/Videos';
  static const String musicFolder = 'MediaGrab/Music';
  static const String whatsappFolder = 'MediaGrab/WhatsApp';

  /// Default video quality preference key.
  static const String defaultQualityKey = 'default_quality';
  static const String defaultQualityValue = '720p';

  /// Theme preference key.
  static const String themeModeKey = 'theme_mode';

  /// Supported platforms (for UI shortcuts).
  static const List<PlatformShortcut> platforms = [
    PlatformShortcut(
      name: 'YouTube',
      url: 'https://m.youtube.com',
      color: 0xFFFF0000,
      icon: '▶',
    ),
    PlatformShortcut(
      name: 'TikTok',
      url: 'https://www.tiktok.com',
      color: 0xFF010101,
      icon: '♪',
    ),
    PlatformShortcut(
      name: 'Instagram',
      url: 'https://www.instagram.com',
      color: 0xFFE1306C,
      icon: '📷',
    ),
    PlatformShortcut(
      name: 'Facebook',
      url: 'https://m.facebook.com',
      color: 0xFF1877F2,
      icon: 'f',
    ),
    PlatformShortcut(
      name: 'Twitter',
      url: 'https://x.com',
      color: 0xFF1DA1F2,
      icon: '𝕏',
    ),
    PlatformShortcut(
      name: 'WhatsApp',
      url: 'https://web.whatsapp.com',
      color: 0xFF25D366,
      icon: '✆',
    ),
  ];
}

/// Quick-launch shortcut for an external platform shown in the browser.
class PlatformShortcut {
  const PlatformShortcut({
    required this.name,
    required this.url,
    required this.color,
    required this.icon,
  });

  final String name;
  final String url;
  final int color;
  final String icon;
}
