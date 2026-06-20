import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/media_item.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/format_utils.dart';
import 'media_thumbnail.dart';

/// iOS-style card displaying a single [MediaItem].
class MediaCard extends ConsumerWidget {
  const MediaCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.showAuthor = true,
  });

  final MediaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: MediaThumbnail(url: item.thumbnailUrl),
              ),
              // Duration badge (iOS-style)
              if (item.duration != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      FormatUtils.duration(item.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Small download arrow (Snaptube-style)
              Positioned(
                left: 6,
                bottom: 6,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_down,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (showAuthor) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.author != null)
                  Expanded(
                    child: Text(
                      item.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                      ),
                    ),
                  ),
                if (item.viewCount != null)
                  Text(
                    '· ${FormatUtils.views(item.viewCount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
