import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/download_manager.dart';
import '../services/youtube_service.dart';

class DownloadSheet extends ConsumerStatefulWidget {
  const DownloadSheet({super.key, required this.item});
  final MediaItem item;

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  List<QualityOption>? _options;
  int _selected = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.item.platform != Platform.youtube) {
      setState(() {
        _options = [
          QualityOption(label: 'MP4', sizeBytes: 0, url: widget.item.streamUrl!, isAudio: false, container: 'mp4'),
          QualityOption(label: 'MP3', sizeBytes: 0, url: widget.item.streamUrl!, isAudio: true, container: 'mp3'),
        ];
        _loading = false;
      });
      return;
    }
    try {
      final svc = YouTubeService();
      final list = await svc.getQualities(widget.item.id);
      svc.dispose();
      if (!mounted) return;
      setState(() {
        _options = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF8E8E93).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تحميل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark, size: 22, color: const Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            // Item preview
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                widget.item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                ),
              ),
            ),
            const Divider(height: 1),
            // Options list
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator(radius: 14))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _options!.length,
                      separatorBuilder: (_, __) => const Divider(indent: 56, height: 1),
                      itemBuilder: (context, i) => _option(i),
                    ),
            ),
            const Divider(height: 1),
            // Confirm button
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _loading ? null : _enqueue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('تحميل الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(int i) {
    final opt = _options![i];
    final isSel = i == _selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _selected = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Custom radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                  width: 2,
                ),
              ),
              child: isSel
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Icon(
              opt.isAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
              color: opt.isAudio ? const Color(0xFFFF3B30) : const Color(0xFF007AFF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${opt.isAudio ? "صوتي" : "فيديو"} · ${opt.label}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            if (opt.sizeBytes > 0)
              Text(
                _fmtBytes(opt.sizeBytes),
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtBytes(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _enqueue() async {
    final opt = _options![_selected];
    await ref.read(downloadManagerProvider.notifier).enqueue(
          media: widget.item.copyWith(streamUrl: opt.url),
          streamUrl: opt.url,
          quality: opt.label,
          format: opt.container,
          isAudio: opt.isAudio,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }
}
