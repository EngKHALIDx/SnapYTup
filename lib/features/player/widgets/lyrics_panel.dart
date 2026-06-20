import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/lyrics_service.dart';
import '../../../core/theme/app_colors.dart';

/// Sliding-up panel that fetches and displays lyrics for the currently
/// playing track. Snaptube shows lyrics inline with the music player.
class LyricsPanel extends ConsumerWidget {
  const LyricsPanel({super.key, required this.artist, required this.title});

  final String artist;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lyricsForProvider((artist: artist, title: title)));
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Grabber
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.lyrics_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lyrics · $title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Lyrics body
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _LyricsEmpty(
                message: 'Could not load lyrics.\nCheck your network and try again.',
              ),
              data: (lyrics) => lyrics == null
                  ? const _LyricsEmpty(
                      message: 'No lyrics found for this track.\nTry a different title or artist.',
                    )
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          lyrics,
                          style: const TextStyle(height: 1.5, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsEmpty extends StatelessWidget {
  const _LyricsEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, size: 48, color: AppColors.textSecondaryDark),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
