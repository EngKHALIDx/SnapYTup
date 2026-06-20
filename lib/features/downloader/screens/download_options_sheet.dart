import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/repositories/youtube_repository.dart';

/// Bottom sheet that shows available download qualities for a YouTube video
/// and lets the user enqueue a download.
///
/// For non-YouTube [MediaItem]s we assume `streamUrl` is already set and offer
/// a single "Direct download" row.
class DownloadOptionsSheet extends ConsumerStatefulWidget {
  const DownloadOptionsSheet({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends ConsumerState<DownloadOptionsSheet> {
  List<StreamQualityOption>? _qualities;
  bool _loading = true;
  String? _error;
  bool _showMoreFormats = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.item.platform != MediaPlatform.youtube) {
      // Direct URL already set — skip the qualities fetch.
      setState(() {
        _qualities = [];
        _loading = false;
      });
      return;
    }
    try {
      final repo = ref.read(youTubeRepoProvider);
      final list = await repo.getQualities(widget.item.id);
      if (!mounted) return;
      setState(() {
        _qualities = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load qualities: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    final qualities = _qualities ?? [];

    // Non-YouTube case: a single direct-download row.
    if (widget.item.platform != MediaPlatform.youtube) {
      return ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(icon: Icons.movie, text: 'Video (MP4)', color: AppColors.primary),
          _OptionTile(
            leading: const Icon(Icons.movie),
            title: 'Direct download',
            subtitle: 'Best available quality',
            onTap: () => _enqueue(
              streamUrl: widget.item.streamUrl!,
              quality: 'video',
              format: 'mp4',
              extractAudio: false,
            ),
          ),
          const SizedBox(height: 12),
          _SectionLabel(icon: Icons.music_note, text: 'Audio (MP3 / M4A)', color: AppColors.secondary),
          _OptionTile(
            leading: const Icon(Icons.music_note),
            title: 'Direct download',
            subtitle: 'Audio only',
            onTap: () => _enqueue(
              streamUrl: widget.item.streamUrl!,
              quality: 'audio',
              format: 'mp4',
              extractAudio: true,
            ),
          ),
        ],
      );
    }

    // YouTube case: split into Video and Audio groups (Snaptube pattern).
    final videoQualities = qualities.where((q) => !q.isAudioOnly).toList();
    final audioQualities = qualities.where((q) => q.isAudioOnly).toList();

    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            // Video group
            _SectionLabel(icon: Icons.movie, text: 'Video (MP4)', color: AppColors.primary),
            for (final q in (_showMoreFormats ? videoQualities : videoQualities.take(4)))
              _OptionTile(
                leading: const Icon(Icons.movie_outlined),
                title: q.label,
                subtitle: FormatUtils.bytes(q.sizeBytes),
                onTap: () => _enqueue(
                  streamUrl: q.url,
                  quality: q.label,
                  format: 'mp4',
                  extractAudio: false,
                ),
              ),
            // Audio group
            const SizedBox(height: 12),
            _SectionLabel(icon: Icons.music_note, text: 'Audio (MP3 / M4A)', color: AppColors.secondary),
            for (final q in (_showMoreFormats ? audioQualities : audioQualities.take(3)))
              _OptionTile(
                leading: const Icon(Icons.music_note_outlined),
                title: q.label,
                subtitle: FormatUtils.bytes(q.sizeBytes),
                onTap: () => _enqueue(
                  streamUrl: q.url,
                  quality: q.label,
                  format: q.isAudioOnly ? 'm4a' : 'mp4',
                  extractAudio: q.isAudioOnly,
                ),
              ),
            // "More Formats" expander (Snaptube pattern)
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showMoreFormats = !_showMoreFormats),
                icon: Icon(_showMoreFormats ? Icons.expand_less : Icons.expand_more),
                label: Text(_showMoreFormats ? 'Show less' : 'More Formats'),
              ),
            ),
            // Subtitles placeholder
            const Divider(),
            _OptionTile(
              leading: const Icon(Icons.subtitles_outlined, color: AppColors.info),
              title: 'Subtitles / CC',
              subtitle: 'Pick subtitle language',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No subtitles available for this video.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _enqueue({
    required String streamUrl,
    required String quality,
    required String format,
    required bool extractAudio,
  }) async {
    final mgr = ref.read(downloadManagerProvider.notifier);
    await mgr.enqueue(
      media: widget.item.copyWith(streamUrl: streamUrl),
      quality: quality,
      format: format,
      extractAudio: extractAudio,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download queued.'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: navigate to download queue
          },
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.download_for_offline, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }
}

/// Section label inside the download sheet (e.g. "Video (MP4)", "Audio (MP3)").
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
