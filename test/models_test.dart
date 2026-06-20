import 'package:flutter_test/flutter_test.dart';
import 'package:snap_yt/models/media_item.dart';

void main() {
  test('MediaItem copyWith merges streamUrl correctly', () {
    final a = MediaItem(
      id: 'abc',
      title: 'Test',
      platform: Platform.youtube,
      sourceUrl: 'https://example.com',
    );
    final b = a.copyWith(streamUrl: 'https://stream.url');
    expect(b.id, 'abc');
    expect(b.title, 'Test');
    expect(b.streamUrl, 'https://stream.url');
  });

  test('Platform labels are non-empty Arabic strings', () {
    expect(Platform.youtube.label, 'يوتيوب');
    expect(Platform.tiktok.label, 'تيك توك');
    expect(Platform.instagram.label, 'انستغرام');
    expect(Platform.facebook.label, 'فيسبوك');
    expect(Platform.unknown.label.isNotEmpty, true);
  });
}
