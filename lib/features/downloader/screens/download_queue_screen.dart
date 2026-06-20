import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/download_task.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// iOS-style Download Manager: live progress, file size, speed, ETA,
/// pause/resume/cancel/retry actions.
class DownloadQueueScreen extends ConsumerWidget {
  const DownloadQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final mgr = ref.read(downloadManagerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active = tasks.where((t) => t.isActive).toList();
    final done = tasks.where((t) => !t.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (tasks.any((t) => t.isActive))
            IconButton(
              icon: const Icon(CupertinoIcons.stop_circle),
              tooltip: 'Cancel all',
              onPressed: () {
                for (final t in tasks.where((t) => t.isActive)) {
                  mgr.cancel(t.id);
                }
              },
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash),
            tooltip: 'Clear finished',
            onPressed: () async {
              for (final t in tasks.where((t) => !t.isActive)) {
                await mgr.remove(t.id);
              }
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? _buildEmpty(isDark)
          : CupertinoScrollbar(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (active.isNotEmpty) ...[
                    _SectionHeader('Active', isDark),
                    for (final t in active) _TaskCard(taskId: t.id),
                  ],
                  if (done.isNotEmpty) ...[
                    if (active.isNotEmpty) const SizedBox(height: 16),
                    _SectionHeader('Finished', isDark),
                    for (final t in done) _TaskCard(taskId: t.id),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.arrow_down_circle,
            size: 72,
            color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No Downloads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your downloads will appear here.',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final task = tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return const SizedBox.shrink();

    final isActive = task.isActive;
    final isFailed = task.status == DownloadStatus.failed;
    final isCompleted = task.status == DownloadStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (task.extractAudio ? AppColors.systemPurple : AppColors.systemPink)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              task.extractAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
              color: task.extractAudio ? AppColors.systemPurple : AppColors.systemPink,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (isActive && task.totalBytes > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.lightSurfaceAlt,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${FormatUtils.bytes(task.downloadedBytes)} of ${FormatUtils.bytes(task.totalBytes)}'
                    '${task.bytesPerSecond != null ? ' · ${FormatUtils.rate(task.bytesPerSecond)}' : ''}'
                    '${task.etaSeconds != null ? ' · ${FormatUtils.eta(task.etaSeconds)} left' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.labelSecondaryDark
                          : AppColors.labelSecondary,
                    ),
                  ),
                ] else if (isFailed) ...[
                  Text(
                    'Failed — ${task.error ?? "unknown error"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.systemRed),
                  ),
                ] else ...[
                  Text(
                    isCompleted
                        ? '${task.quality} · ${FormatUtils.bytes(task.totalBytes)}'
                        : 'Queued',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted
                          ? AppColors.systemGreen
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.labelSecondaryDark
                              : AppColors.labelSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action
          if (isActive)
            IconButton(
              icon: const Icon(CupertinoIcons.pause_fill, size: 22),
              onPressed: () => ref.read(downloadManagerProvider.notifier).pause(task.id),
            )
          else if (task.canRetry)
            IconButton(
              icon: const Icon(CupertinoIcons.refresh, size: 22),
              onPressed: () => ref.read(downloadManagerProvider.notifier).retry(task.id),
            )
          else if (isCompleted)
            const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.systemGreen, size: 26),
        ],
      ),
    );
  }
}
