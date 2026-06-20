import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// iOS-style network image with a clean placeholder.
class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  final String? url;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (url == null || url!.isEmpty) {
      return _placeholder(isDark);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url!,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(isDark, loading: true);
        },
        errorBuilder: (_, __, ___) => _placeholder(isDark),
      ),
    );
  }

  Widget _placeholder(bool isDark, {bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: loading
            ? const CupertinoActivityIndicator()
            : Icon(
                CupertinoIcons.film,
                color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary,
                size: 28,
              ),
      ),
    );
  }
}
