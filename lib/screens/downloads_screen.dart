import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/download_task.dart';
import '../services/download_manager.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final mgr = ref.read(downloadManagerProvider.notifier);
    final active = tasks.where((t) => t.isActive).toList();
    final done = tasks.where((t) => !t.isActive).toList();

    return Scaffold(
      body: SafeArea(
        child: tasks.isEmpty
            ? _empty(context)
            : ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (active.isNotEmpty) ...[
                    _section(context, 'نشط · ${active.length}'),
                    for (final t in active) _activeCard(context, t, mgr),
                  ],
                  if (done.isNotEmpty) ...[
                    if (active.isNotEmpty) const SizedBox(height: 16),
                    _sectionHeader(context, 'مكتمل', onClear: () => mgr.clearFinished()),
                    for (final t in done) _doneCard(context, t, mgr),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _section(BuildContext c, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.4)),
      );

  Widget _sectionHeader(BuildContext c, String text, {VoidCallback? onClear}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.4)),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Text('مسح الكل',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF007AFF))),
              ),
          ],
        ),
      );

  Widget _activeCard(BuildContext c, DownloadTask t, DownloadManager mgr) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final label = isDark ? Colors.white : Colors.black;
    final secondary = const Color(0xFF8E8E93);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(t.isAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
                  color: const Color(0xFF007AFF), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: label)),
              ),
              // State indicator
              if (t.state == DownloadState.running)
                GestureDetector(
                  onTap: () => mgr.pause(t.id),
                  child: const Icon(CupertinoIcons.pause_circle_fill,
                      size: 26, color: Color(0xFF007AFF)),
                )
              else if (t.state == DownloadState.paused)
                GestureDetector(
                  onTap: () => mgr.resume(t.id),
                  child: const Icon(CupertinoIcons.play_circle_fill,
                      size: 26, color: Color(0xFF007AFF)),
                )
              else if (t.state == DownloadState.queued)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(radius: 8),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => mgr.cancel(t.id),
                child: const Icon(CupertinoIcons.xmark_circle,
                    size: 22, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: t.progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(height: 8),
          // Progress info
          Row(
            children: [
              Text('${(t.progress * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
              const SizedBox(width: 12),
              if (t.sizeText.isNotEmpty)
                Text(t.sizeText, style: TextStyle(fontSize: 12, color: secondary)),
              const Spacer(),
              if (t.speedText.isNotEmpty)
                Text(t.speedText, style: TextStyle(fontSize: 12, color: secondary)),
              if (t.etaSeconds != null) ...[
                const SizedBox(width: 8),
                Text('${t.etaSeconds}s', style: TextStyle(fontSize: 12, color: secondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneCard(BuildContext c, DownloadTask t, DownloadManager mgr) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final label = isDark ? Colors.white : Colors.black;
    final isFailed = t.state == DownloadState.failed;
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(CupertinoIcons.delete, color: Colors.white),
      ),
      onDismissed: (_) => mgr.remove(t.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isFailed
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.checkmark_circle_fill,
              color: isFailed ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.media.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: label)),
                  const SizedBox(height: 2),
                  Text(
                    isFailed
                        ? 'فشل: ${t.error ?? "خطأ غير معروف"}'
                        : '${t.quality} · ${t.format.toUpperCase()} · ${t.sizeText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: isFailed ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            if (isFailed)
              GestureDetector(
                onTap: () => mgr.retry(t.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('إعادة',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.arrow_down_circle,
              size: 72, color: const Color(0xFF8E8E93).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('لا توجد تنزيلات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('ابحث عن فيديو واضغط زر التنزيل',
              style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}
