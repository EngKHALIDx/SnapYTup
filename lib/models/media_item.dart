/// Source platform.
enum Platform { youtube, tiktok, instagram, facebook, twitter, browser, unknown }

extension PlatformX on Platform {
  String get label => switch (this) {
        Platform.youtube => 'يوتيوب',
        Platform.tiktok => 'تيك توك',
        Platform.instagram => 'انستغرام',
        Platform.facebook => 'فيسبوك',
        Platform.twitter => 'تويتر',
        Platform.browser => 'متصفح',
        Platform.unknown => 'غير معروف',
      };
}

/// One playable / downloadable media item.
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
    this.viewCount,
  });

  final String id;
  final String title;
  final Platform platform;
  final String sourceUrl;
  final String? streamUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? author;
  final int? viewCount;

  MediaItem copyWith({String? streamUrl}) => MediaItem(
        id: id,
        title: title,
        platform: platform,
        sourceUrl: sourceUrl,
        streamUrl: streamUrl ?? this.streamUrl,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
        author: author,
        viewCount: viewCount,
      );
}
