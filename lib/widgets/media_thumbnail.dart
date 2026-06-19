import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Reusable network image with a dark gradient placeholder.
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
          return _placeholder(isDark, showSpinner: true);
        },
        errorBuilder: (_, __, ___) => _placeholder(isDark),
      ),
    );
  }

  Widget _placeholder(bool isDark, {bool showSpinner = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ],
        ),
      ),
      child: showSpinner
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Icon(
              Icons.play_circle_outline,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              size: 36,
            ),
    );
  }
}
