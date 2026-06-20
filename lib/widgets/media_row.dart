import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/media_item.dart';

class Thumbnail extends StatelessWidget {
  const Thumbnail({super.key, required this.url, this.radius = 8});
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? Container(color: placeholderColor)
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: placeholderColor),
              errorWidget: (_, __, ___) => Container(
                color: placeholderColor,
                child: Icon(CupertinoIcons.film,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    size: 24),
              ),
            ),
    );
  }
}

class MediaRow extends StatelessWidget {
  const MediaRow({super.key, required this.item, this.onTap, this.trailing});
  final MediaItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 100, height: 56, child: Thumbnail(url: item.thumbnailUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
                  if (item.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [item.author, if (item.viewCount != null) '${_fmtViews(item.viewCount!)} مشاهدة'].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }

  String _fmtViews(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}
