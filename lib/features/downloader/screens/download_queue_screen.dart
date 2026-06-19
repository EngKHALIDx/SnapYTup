import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/download_task.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Active + completed download queue.
class DownloadQueueScreen extends ConsumerWidget {
  const DownloadQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final mgr = ref.read(downloadManagerProvider.notifier);

    final active = tasks.where((t) => t.isActive).toList();
    final done = tasks.where((t) => !t.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (tasks.any((t) => t.isActive))
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel all',
              onPressed: () {
                for (final t in tasks.where((t) => t.isActive)) {
                  mgr.cancel(t.id);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear completed',
            onPressed: () async {
              for (final t in tasks.where((t) => !t.isActive)) {
                await mgr.remove(t.id);
              }
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const _EmptyBox()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (active.isNotEmpty) ...[
                  const _SectionHeader('Active'),
                  for (final t in active) _TaskCard(taskId: t.id),
                  const SizedBox(height: 16),
                ],
                if (done.isNotEmpty) ...[
                  const _SectionHeader('Completed'),
                  for (final t in done) _TaskCard(taskId: t.id),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      );
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done, size: 64, color: AppColors.textSecondaryDark),
          SizedBox(height: 8),
          Text('No downloads yet.'),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                task.extractAudio ? Icons.music_note : Icons.movie,
                color: AppColors.primary,
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (isActive && task.totalBytes > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${FormatUtils.bytes(task.downloadedBytes)} / ${FormatUtils.bytes(task.totalBytes)} '
                      '· ${FormatUtils.rate(task.bytesPerSecond)}'
                      '${task.etaSeconds != null ? ' · ETA ${FormatUtils.eta(task.etaSeconds)}' : ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ] else if (isFailed) ...[
                    Text(
                      'Failed: ${task.error ?? "unknown"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                  ] else ...[
                    Text(
                      '${task.quality} · ${FormatUtils.bytes(task.totalBytes)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action button
            if (isActive)
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () => ref.read(downloadManagerProvider.notifier).pause(task.id),
              )
            else if (task.canRetry)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(downloadManagerProvider.notifier).retry(task.id),
              )
            else
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
          ],
        ),
      ),
    );
  }
}
