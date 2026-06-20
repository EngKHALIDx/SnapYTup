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
                children: [
                  if (active.isNotEmpty) ...[
                    _section('نشط', context),
                    for (final t in active) _activeCard(t, mgr, context),
                  ],
                  if (done.isNotEmpty) ...[
                    if (active.isNotEmpty) const SizedBox(height: 16),
                    _section('مكتمل', context),
                    for (final t in done) _doneCard(t, mgr, context),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  Widget _section(String t, BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E93),
                letterSpacing: 0.5)),
      );

  Widget _activeCard(DownloadTask t, dynamic mgr, BuildContext c) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    final speed = t.speedBps;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(t.isAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
                  color: const Color(0xFF007AFF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: () => mgr.pause(t.id),
                child: const Icon(CupertinoIcons.pause_circle, size: 24, color: Color(0xFF007AFF)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: t.progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${(t.progress * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(width: 12),
              if (speed != null)
                Text('${(speed / 1024).toStringAsFixed(0)} KB/s',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(t.quality,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneCard(DownloadTask t, dynamic mgr, BuildContext c) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    final isFailed = t.state == DownloadState.failed;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isFailed ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.checkmark_circle_fill,
              color: isFailed ? const Color(0xFFFF3B30) : const Color(0xFF34C759), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  isFailed ? 'فشل: ${t.error ?? ""}' : '${t.quality} · ${t.format}',
                  style: TextStyle(fontSize: 12, color: isFailed ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
          if (isFailed)
            GestureDetector(
              onTap: () => mgr.resume(t.id),
              child: const Icon(CupertinoIcons.refresh, size: 22, color: Color(0xFF007AFF)),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => mgr.remove(t.id),
            child: const Icon(CupertinoIcons.delete, size: 20, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.arrow_down_circle, size: 64, color: const Color(0xFF8E8E93).withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('لا توجد تنزيلات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('تنزيلاتك ستظهر هنا', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}
