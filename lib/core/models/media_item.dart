/// Source platform that supplied a media item.
enum MediaPlatform {
  youtube,
  tiktok,
  instagram,
  facebook,
  twitter,
  whatsapp,
  browser,
  unknown;

  String get label {
    switch (this) {
      case MediaPlatform.youtube:    return 'YouTube';
      case MediaPlatform.tiktok:     return 'TikTok';
      case MediaPlatform.instagram:  return 'Instagram';
      case MediaPlatform.facebook:   return 'Facebook';
      case MediaPlatform.twitter:    return 'Twitter';
      case MediaPlatform.whatsapp:   return 'WhatsApp';
      case MediaPlatform.browser:    return 'Browser';
      case MediaPlatform.unknown:    return 'Unknown';
    }
  }
}

/// Type of media an item represents.
enum MediaType { video, audio, image }

/// Represents a single playable / downloadable media item coming from any
/// of the supported platforms.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.sourceUrl,
    this.streamUrl,
    this.thumbnailUrl,
    this.duration,
    this.author,
    this.authorAvatar,
    this.viewCount,
    this.uploadDate,
    this.description,
    this.type = MediaType.video,
    this.availableQualities = const ['720p'],
    this.fileSizeBytes,
  });

  /// Unique id (usually the platform's native id, e.g. YouTube video id).
  final String id;
  final String title;
  final MediaPlatform platform;
  final String sourceUrl;
  final String? streamUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? author;
  final String? authorAvatar;
  final int? viewCount;
  final DateTime? uploadDate;
  final String? description;
  final MediaType type;
  final List<String> availableQualities;
  final int? fileSizeBytes;

  MediaItem copyWith({
    String? id,
    String? title,
    MediaPlatform? platform,
    String? sourceUrl,
    String? streamUrl,
    String? thumbnailUrl,
    Duration? duration,
    String? author,
    String? authorAvatar,
    int? viewCount,
    DateTime? uploadDate,
    String? description,
    MediaType? type,
    List<String>? availableQualities,
    int? fileSizeBytes,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      viewCount: viewCount ?? this.viewCount,
      uploadDate: uploadDate ?? this.uploadDate,
      description: description ?? this.description,
      type: type ?? this.type,
      availableQualities: availableQualities ?? this.availableQualities,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
