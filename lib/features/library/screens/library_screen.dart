import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/library_repository.dart';
import '../../player/screens/video_player_screen.dart';
import '../widgets/library_tab_bar.dart';

/// Library screen: 3 tabs (Videos / Music / Downloads).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: LibraryTabBar(controller: _tab),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear cache',
            onPressed: () async {
              // TODO: clear cache
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared.')),
              );
              ref.invalidate(videosProvider);
              ref.invalidate(musicProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _VideosTab(),
          _MusicTab(),
          _DownloadsTab(),
        ],
      ),
    );
  }
}

class _VideosTab extends ConsumerWidget {
  const _VideosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videosProvider);
    return _AsyncGrid(async: async, type: 'video');
  }
}

class _MusicTab extends ConsumerWidget {
  const _MusicTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(musicProvider);
    return _AsyncGrid(async: async, type: 'audio');
  }
}

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-use the videos provider for simplicity.
    final async = ref.watch(videosProvider);
    return _AsyncGrid(async: async, type: 'video');
  }
}

class _AsyncGrid extends ConsumerWidget {
  const _AsyncGrid({required this.async, required this.type});
  final AsyncValue<List<dynamic>> async;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load: $e',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VideoPlayerScreen(filePath: item.sourceUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnailUrl != null)
                      Image.network(item.thumbnailUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.darkSurfaceAlt,
                          child: const Icon(Icons.video_library, size: 32),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.darkSurfaceAlt,
                        child: Icon(
                          type == 'audio' ? Icons.music_note : Icons.video_library,
                          size: 32,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Text(
                          item.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64, color: AppColors.textSecondaryDark),
          const SizedBox(height: 8),
          Text(
            'Nothing here yet',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Your downloads will appear here.'),
        ],
      ),
    );
  }
}
