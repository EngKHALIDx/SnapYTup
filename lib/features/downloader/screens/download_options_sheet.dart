import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/repositories/youtube_repository.dart';
import 'download_queue_screen.dart';

/// Snaptube-style bottom sheet for selecting download format & quality.
///
/// Matches the actual Snaptube UI from the user's screenshot:
/// - Title bar with "Download from YouTube" + close arrow
/// - Vertical list of radio-button options
/// - Each row: [badge: صوتي/فيديو] [format name + bitrate/resolution] [size] [quality description]
/// - Bottom: "Previous downloads" link + "Install" button
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.item.platform != MediaPlatform.youtube) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            // Header — Snaptube style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _sheetTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.labelPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close,
                        size: 22,
                        color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: _buildBody(controller),
            ),
            // Footer — Snaptube style
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Previous downloads link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DownloadQueueScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'التنزيلات السابقة',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Install button (Snaptube style)
                  FilledButton(
                    onPressed: _loading || _qualities == null
                        ? null
                        : () => _enqueueSelected(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'تثبيت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sheetTitle() {
    switch (widget.item.platform) {
      case MediaPlatform.youtube:
        return 'التحميل من يوتيوب';
      case MediaPlatform.tiktok:
        return 'التحميل من تيك توك';
      case MediaPlatform.instagram:
        return 'التحميل من انستغرام';
      case MediaPlatform.facebook:
        return 'التحميل من فيسبوك';
      case MediaPlatform.twitter:
        return 'التحميل من تويتر';
      default:
        return 'تحميل';
    }
  }

  Widget _buildBody(ScrollController controller) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.systemRed),
          ),
        ),
      );
    }

    final qualities = _qualities ?? [];
    final options = <_DownloadOption>[];

    if (widget.item.platform != MediaPlatform.youtube) {
      // Direct download case
      options.add(_DownloadOption(
        type: OptionType.video,
        format: 'MP4',
        bitrate: '',
        sizeBytes: null,
        qualityDescription: 'أفضل جودة',
        streamUrl: widget.item.streamUrl!,
      ));
      options.add(_DownloadOption(
        type: OptionType.audio,
        format: 'MP3',
        bitrate: '128K',
        sizeBytes: null,
        qualityDescription: 'صوت عالي الجودة',
        streamUrl: widget.item.streamUrl!,
      ));
    } else {
      // YouTube — split by type
      for (final q in qualities) {
        if (q.isAudioOnly) {
          options.add(_DownloadOption(
            type: OptionType.audio,
            format: q.container.toUpperCase() == 'MP4' ? 'M4A' : q.container.toUpperCase(),
            bitrate: q.label.replaceAll('Audio ', ''),
            sizeBytes: q.sizeBytes,
            qualityDescription: _audioQualityDescription(q.label),
            streamUrl: q.url,
          ));
        } else {
          options.add(_DownloadOption(
            type: OptionType.video,
            format: 'MP4',
            bitrate: q.label,
            sizeBytes: q.sizeBytes,
            qualityDescription: _videoQualityDescription(q.label),
            streamUrl: q.url,
          ));
        }
      }
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: options.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, i) {
        final opt = options[i];
        final isSelected = i == _selectedIndex;
        return _OptionRow(
          option: opt,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedIndex = i),
        );
      },
    );
  }

  String _audioQualityDescription(String label) {
    if (label.contains('320K')) return 'جودة عالية جداً';
    if (label.contains('160K') || label.contains('128K')) return 'جودة عالية';
    if (label.contains('70K') || label.contains('96K')) return 'جودة متوسطة';
    return 'جودة منخفضة';
  }

  String _videoQualityDescription(String label) {
    if (label.contains('2160') || label.contains('1440')) return 'جودة عالية جداً (HD)';
    if (label.contains('1080')) return 'جودة عالية (HD)';
    if (label.contains('720')) return 'جودة عالية';
    if (label.contains('480')) return 'جودة متوسطة';
    if (label.contains('360')) return 'جودة متوسطة';
    if (label.contains('240')) return 'جودة منخفضة';
    return 'جودة منخفضة';
  }

  Future<void> _enqueueSelected() async {
    final qualities = _qualities ?? [];
    final options = <_DownloadOption>[];

    if (widget.item.platform != MediaPlatform.youtube) {
      options.add(_DownloadOption(
        type: OptionType.video,
        format: 'MP4',
        bitrate: '',
        sizeBytes: null,
        qualityDescription: '',
        streamUrl: widget.item.streamUrl!,
      ));
      options.add(_DownloadOption(
        type: OptionType.audio,
        format: 'MP3',
        bitrate: '128K',
        sizeBytes: null,
        qualityDescription: '',
        streamUrl: widget.item.streamUrl!,
      ));
    } else {
      for (final q in qualities) {
        if (q.isAudioOnly) {
          options.add(_DownloadOption(
            type: OptionType.audio,
            format: q.container.toUpperCase() == 'MP4' ? 'M4A' : q.container.toUpperCase(),
            bitrate: q.label.replaceAll('Audio ', ''),
            sizeBytes: q.sizeBytes,
            qualityDescription: '',
            streamUrl: q.url,
          ));
        } else {
          options.add(_DownloadOption(
            type: OptionType.video,
            format: 'MP4',
            bitrate: q.label,
            sizeBytes: q.sizeBytes,
            qualityDescription: '',
            streamUrl: q.url,
          ));
        }
      }
    }

    if (_selectedIndex >= options.length) return;
    final opt = options[_selectedIndex];
    final mgr = ref.read(downloadManagerProvider.notifier);
    await mgr.enqueue(
      media: widget.item.copyWith(streamUrl: opt.streamUrl),
      quality: opt.bitrate.isEmpty ? opt.format : opt.bitrate,
      format: opt.format.toLowerCase(),
      extractAudio: opt.type == OptionType.audio,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DownloadQueueScreen(),
      ),
    );
  }
}

enum OptionType { audio, video }

class _DownloadOption {
  const _DownloadOption({
    required this.type,
    required this.format,
    required this.bitrate,
    required this.sizeBytes,
    required this.qualityDescription,
    required this.streamUrl,
  });
  final OptionType type;
  final String format;
  final String bitrate;
  final int? sizeBytes;
  final String qualityDescription;
  final String streamUrl;
}

/// One row in the download options list. Matches Snaptube's layout exactly:
/// [radio] [badge صوتي/فيديو] [format/bitrate] [size] [quality description]
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _DownloadOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAudio = option.type == OptionType.audio;
    final badgeColor = isAudio ? AppColors.systemRed : AppColors.systemBlue;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Radio button (Snaptube style: white outline, blue fill)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black45),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Type badge (Snaptube style: "صوتي" red or "فيديو" blue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isAudio ? 'صوتي' : 'فيديو',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Format name + bitrate + size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.format,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.labelPrimary,
                        ),
                      ),
                      if (option.bitrate.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${option.bitrate})',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (option.sizeBytes != null)
                        Text(
                          FormatUtils.bytes(option.sizeBytes),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.qualityDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
