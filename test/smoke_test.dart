// Smoke tests for MediaGrab core utilities and models.
//
// These tests don't require a Flutter binding and exercise the pure-Dart
// parts of the codebase so CI can run them quickly.

import 'package:flutter_test/flutter_test.dart';
import 'package:snap_yt/core/constants/app_config.dart';
import 'package:snap_yt/core/models/category_item.dart';
import 'package:snap_yt/core/models/download_task.dart';
import 'package:snap_yt/core/models/media_item.dart';
import 'package:snap_yt/core/services/app_update_service.dart';
import 'package:snap_yt/core/utils/format_utils.dart';

void main() {
  group('FormatUtils.bytes', () {
    test('formats bytes correctly', () {
      expect(FormatUtils.bytes(0), '0 B');
      expect(FormatUtils.bytes(1023), '1023 B');
      expect(FormatUtils.bytes(1024), '1.0 KB');
      expect(FormatUtils.bytes(1024 * 1024), '1.0 MB');
      expect(FormatUtils.bytes(1024 * 1024 * 1024), '1.0 GB');
    });

    test('handles null and negative values', () {
      expect(FormatUtils.bytes(null), '0 B');
      expect(FormatUtils.bytes(-10), '0 B');
    });
  });

  group('FormatUtils.duration', () {
    test('formats minutes and seconds', () {
      expect(FormatUtils.duration(Duration.zero), '00:00');
      expect(FormatUtils.duration(const Duration(seconds: 5)), '00:05');
      expect(FormatUtils.duration(const Duration(minutes: 3, seconds: 7)), '03:07');
    });

    test('formats hours when present', () {
      expect(FormatUtils.duration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });

    test('handles null', () {
      expect(FormatUtils.duration(null), '--:--');
    });
  });

  group('FormatUtils.views', () {
    test('formats small counts', () {
      expect(FormatUtils.views(0), '0 views');
      expect(FormatUtils.views(999), '999 views');
    });

    test('formats large counts', () {
      expect(FormatUtils.views(1500), '1.5K views');
      expect(FormatUtils.views(2_500_000), '2.5M views');
      expect(FormatUtils.views(3_000_000_000), '3.0B views');
    });

    test('handles null', () {
      expect(FormatUtils.views(null), '');
    });
  });

  group('MediaItem', () {
    test('copyWith merges fields', () {
      final a = MediaItem(
        id: 'abc',
        title: 'Original',
        platform: MediaPlatform.youtube,
        sourceUrl: 'https://example.com',
      );
      final b = a.copyWith(title: 'Updated', streamUrl: 'https://stream');
      expect(b.id, 'abc');
      expect(b.title, 'Updated');
      expect(b.streamUrl, 'https://stream');
      expect(b.platform, MediaPlatform.youtube);
    });

    test('platform labels are non-empty', () {
      for (final p in MediaPlatform.values) {
        expect(p.label.isNotEmpty, true, reason: '$p should have a label');
      }
    });
  });

  group('DownloadTask', () {
    test('isActive is true for queued/running', () {
      final media = MediaItem(
        id: 'x',
        title: 't',
        platform: MediaPlatform.unknown,
        sourceUrl: 's',
      );
      final t = DownloadTask(
        id: '1',
        media: media,
        quality: '720p',
        format: 'mp4',
        savePath: '/tmp/x.mp4',
        status: DownloadStatus.queued,
      );
      expect(t.isActive, true);
      t.status = DownloadStatus.completed;
      expect(t.isActive, false);
    });

    test('canRetry is true for failed and canceled', () {
      final media = MediaItem(
        id: 'x',
        title: 't',
        platform: MediaPlatform.unknown,
        sourceUrl: 's',
      );
      final t = DownloadTask(
        id: '1',
        media: media,
        quality: '720p',
        format: 'mp4',
        savePath: '/tmp/x.mp4',
      );
      t.status = DownloadStatus.failed;
      expect(t.canRetry, true);
      t.status = DownloadStatus.canceled;
      expect(t.canRetry, true);
      t.status = DownloadStatus.completed;
      expect(t.canRetry, false);
    });
  });

  group('homeCategories', () {
    test('has 8 entries', () {
      expect(homeCategories.length, 8);
    });

    test('every entry has a non-empty title and emoji', () {
      for (final c in homeCategories) {
        expect(c.title.isNotEmpty, true);
        expect(c.icon.isNotEmpty, true);
        expect(c.colorValue != 0, true);
      }
    });

    test('every entry has a unique id', () {
      final ids = homeCategories.map((c) => c.id).toSet();
      expect(ids.length, homeCategories.length);
    });
  });

  group('AppUpdateService.isNewer', () {
    final svc = AppUpdateService();
    test('detects newer versions correctly', () {
      expect(svc.isNewer('1.0.0', '1.0.1'), true);
      expect(svc.isNewer('1.0.0', '1.1.0'), true);
      expect(svc.isNewer('1.0.0', '2.0.0'), true);
    });

    test('detects same or older versions correctly', () {
      expect(svc.isNewer('1.0.0', '1.0.0'), false);
      expect(svc.isNewer('2.0.0', '1.0.0'), false);
      expect(svc.isNewer('1.5.0', '1.4.9'), false);
    });

    test('handles different length versions', () {
      expect(svc.isNewer('1.0', '1.0.1'), true);
      expect(svc.isNewer('1.0.0.0', '1.0.0'), false);
    });
  });

  group('Platform shortcuts', () {
    test('includes all main platforms', () {
      final names = AppConfig.platforms.map((p) => p.name).toSet();
      for (final expected in ['YouTube', 'TikTok', 'Instagram', 'Facebook', 'Twitter', 'WhatsApp']) {
        expect(names.contains(expected), true, reason: '$expected should be in shortcuts');
      }
    });

    test('every shortcut has a non-empty URL', () {
      for (final p in AppConfig.platforms) {
        expect(p.url.isNotEmpty, true);
        expect(p.url.startsWith('https://'), true);
      }
    });
  });
}
