import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/download_task.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Snaptube-style active downloads screen. Matches the user's screenshot:
/// - Header: "تحميل (N)" with trash icon + pause-all
/// - Each row: [icon] [title] [progress bar with % + speed] [circular thumbnail]
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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          active.isEmpty ? 'التنزيلات' : 'تحميل (${active.length})',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.labelPrimary,
          ),
        ),
        actions: [
          if (active.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.pause_circle, size: 26),
              color: isDark ? Colors.white : AppColors.labelPrimary,
              onPressed: () {
                for (final t in active) {
                  mgr.pause(t.id);
                }
              },
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash, size: 22),
            color: isDark ? Colors.white : AppColors.labelPrimary,
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
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final t in active) _ActiveTaskCard(taskId: t.id),
                if (active.isNotEmpty && done.isNotEmpty)
                  const Divider(height: 32, indent: 16, endIndent: 16),
                if (done.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'التنزيلات السابقة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                      ),
                    ),
                  ),
                  for (final t in done) _FinishedTaskCard(taskId: t.id),
                ],
              ],
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
            'لا توجد تنزيلات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.labelPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'التنزيلات ستظهر هنا',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Active download row — Snaptube style:
/// [icon] [title + progress bar + % + speed] [circular thumbnail]
class _ActiveTaskCard extends ConsumerWidget {
  const _ActiveTaskCard({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final task = tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (task.extractAudio ? AppColors.systemRed : AppColors.systemBlue)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              task.extractAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
              color: task.extractAudio ? AppColors.systemRed : AppColors.systemBlue,
              size: 20,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.labelPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar — Snaptube style: simple 4px blue bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 4,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightSurfaceAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${(task.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (task.bytesPerSecond != null)
                      Text(
                        FormatUtils.rate(task.bytesPerSecond),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    if (task.etaSeconds != null)
                      Text(
                        FormatUtils.eta(task.etaSeconds),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Circular thumbnail (Snaptube style — vinyl-record-style small circle)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkSurfaceElevated,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: task.media.thumbnailUrl != null
                ? ClipOval(
                    child: Image.network(
                      task.media.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        task.extractAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                  )
                : Icon(
                    task.extractAudio ? CupertinoIcons.music_note : CupertinoIcons.film,
                    color: Colors.white54,
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Finished download row — simpler than active.
class _FinishedTaskCard extends ConsumerWidget {
  const _FinishedTaskCard({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final task = tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFailed = task.status == DownloadStatus.failed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isFailed ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.checkmark_circle_fill,
            color: isFailed ? AppColors.systemRed : AppColors.systemGreen,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.labelPrimary,
                  ),
                ),
                Text(
                  isFailed
                      ? 'فشل: ${task.error ?? ""}'
                      : '${task.quality} · ${FormatUtils.bytes(task.totalBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isFailed
                        ? AppColors.systemRed
                        : (isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (task.canRetry)
            IconButton(
              icon: const Icon(CupertinoIcons.refresh, size: 20),
              color: AppColors.primary,
              onPressed: () => ref.read(downloadManagerProvider.notifier).retry(task.id),
            ),
        ],
      ),
    );
  }
}
