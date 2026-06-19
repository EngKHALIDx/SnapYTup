import 'dart:io' as io;

import 'package:flutter/material.dart';

import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';

/// Grid of WhatsApp status thumbnails.
class StatusGrid extends StatelessWidget {
  const StatusGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.onDownload,
  });

  final List<MediaItem> items;
  final ValueChanged<MediaItem> onTap;
  final ValueChanged<MediaItem>? onDownload;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final isVideo = item.type == MediaType.video;
        return GestureDetector(
          onTap: () => onTap(item),
          onLongPress: onDownload == null ? null : () => onDownload!(item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.thumbnailUrl != null)
                  Image.file(
                    io.File(item.thumbnailUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkSurfaceAlt,
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
                  )
                else
                  Container(
                    color: AppColors.darkSurfaceAlt,
                    child: const Icon(Icons.image, color: Colors.white54),
                  ),
                if (isVideo)
                  const Center(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                if (onDownload != null)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: GestureDetector(
                      onTap: () => onDownload!(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
