import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/generic_video_repository.dart';
import '../../downloader/screens/download_options_sheet.dart';

/// In-app browser with quick-launch buttons for each supported platform and
/// a "detect and download" floating action that scrapes the current page for
/// any embedded `.mp4` URL.
class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late WebViewController _controller;
  String _currentUrl = AppConfig.platforms.first.url;
  bool _isLoading = true;
  String _detectedVideoUrl = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (url) async {
          setState(() {
            _isLoading = false;
            _currentUrl = url;
          });
          await _scanForVideo();
        },
      ))
      ..loadRequest(Uri.parse(_currentUrl));
  }

  /// Inject JS that scans the DOM for any `.mp4` URL and posts it back via
  /// document.title. (Lightweight — does not catch every site but covers most.)
  Future<void> _scanForVideo() async {
    final js = '''
      (function() {
        var found = '';
        // 1) <video> tags with src
        var v = document.querySelector('video source[src], video[src]');
        if (v) found = v.src || v.getAttribute('src') || '';
        // 2) <meta property="og:video">
        if (!found) {
          var m = document.querySelector('meta[property="og:video"], meta[property="og:video:url"], meta[property="og:video:secure_url"]');
          if (m) found = m.content || '';
        }
        // 3) any URL containing ".mp4" in the document HTML
        if (!found) {
          var html = document.documentElement.outerHTML;
          var match = html.match(/https?:\\/\\/[^\\s"'<>]+\\.mp4[^\\s"'<>]*/i);
          if (match) found = match[0];
        }
        return found || '';
      })();
    ''';
    final result = await _controller.runJavaScriptReturningResult(js);
    final url = result.toString().replaceAll('"', '').trim();
    if (url.isNotEmpty && url != 'null') {
      setState(() => _detectedVideoUrl = url);
    } else {
      setState(() => _detectedVideoUrl = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _UrlBar(
          url: _currentUrl,
          onSubmitted: (u) => _controller.loadRequest(Uri.parse(u)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          _PlatformShortcutsBar(
            onPick: (url) => _controller.loadRequest(Uri.parse(url)),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
      floatingActionButton: _detectedVideoUrl.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _onDownloadDetected,
              icon: const Icon(Icons.download),
              label: const Text('Download detected video'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
    );
  }

  Future<void> _onDownloadDetected() async {
    final repo = ref.read(genericVideoRepoProvider);
    final item = await repo.resolve(_detectedVideoUrl);
    if (item == null) {
      // Fallback: build a MediaItem from the raw URL.
      final fallback = MediaItem(
        id: _detectedVideoUrl,
        title: 'Browser video',
        platform: MediaPlatform.browser,
        sourceUrl: _detectedVideoUrl,
        streamUrl: _detectedVideoUrl,
        type: MediaType.video,
      );
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => DownloadOptionsSheet(item: fallback),
      );
      return;
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DownloadOptionsSheet(item: item),
    );
  }
}

class _UrlBar extends StatelessWidget {
  const _UrlBar({required this.url, required this.onSubmitted});
  final String url;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: url);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'https://…',
          prefixIcon: const Icon(Icons.lock_outline, size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _PlatformShortcutsBar extends StatelessWidget {
  const _PlatformShortcutsBar({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: AppConfig.platforms.length,
        itemBuilder: (context, i) {
          final p = AppConfig.platforms[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onPick(p.url),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(p.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p.icon,
                        style: TextStyle(
                          fontSize: 22,
                          color: Color(p.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.name, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
