import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Periodically polls the system clipboard for a video URL. When one is
/// detected, exposes it via [detectedUrlProvider] so the UI can prompt
/// the user with a "Download this?" SnackBar — mimicking Snaptube's
/// auto-detect behavior.
class ClipboardWatcherService {
  ClipboardWatcherService();

  static const _pollInterval = Duration(seconds: 2);
  static const _urlPatterns = [
    r'https?://(?:www\.)?youtube\.com/watch\?v=\S+',
    r'https?://youtu\.be/\S+',
    r'https?://(?:www\.|m\.)?tiktok\.com/\S+',
    r'https?://(?:www\.)?instagram\.com/\S+',
    r'https?://(?:www\.|m\.)?facebook\.com/\S+',
    r'https?://(?:www\.)?(?:twitter|x)\.com/\S+',
    r'https?://vimeo\.com/\S+',
    r'https?://(?:www\.)?dailymotion\.com/\S+',
  ];

  Timer? _timer;
  String? _lastSeen;

  void start(void Function(String url) onDetect) {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) async {
      try {
        final data = await Clipboard.getData('text/plain');
        final text = data?.text?.trim() ?? '';
        if (text.isEmpty || text == _lastSeen) return;
        for (final pattern in _urlPatterns) {
          final regex = RegExp(pattern, caseSensitive: false);
          if (regex.hasMatch(text)) {
            _lastSeen = text;
            onDetect(text);
            return;
          }
        }
      } on PlatformException {
        // Clipboard access can fail silently — ignore.
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Riverpod provider.
final clipboardWatcherProvider = Provider<ClipboardWatcherService>((ref) {
  final svc = ClipboardWatcherService();
  ref.onDispose(svc.stop);
  return svc;
});

/// Last URL detected from the clipboard.
final detectedUrlProvider = StateProvider<String?>((ref) => null);
