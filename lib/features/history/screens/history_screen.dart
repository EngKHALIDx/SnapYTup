import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/media_card.dart';
import '../../downloader/screens/download_options_sheet.dart';

/// History screen with 3 tabs: Watch / Downloads / Favorites.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
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
        title: const Text('History'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Watched'),
            Tab(text: 'Downloads'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _HistoryList(provider: watchHistoryProvider, emptyText: 'No watched videos yet.'),
          _HistoryList(provider: downloadHistoryProvider, emptyText: 'No downloads yet.'),
          _HistoryList(provider: favoritesProvider, emptyText: 'No favorites yet.'),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.provider, required this.emptyText});

  final Provider<List<dynamic>> provider;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textSecondaryDark),
            const SizedBox(height: 8),
            Text(emptyText),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Thumbnail + title (uses MediaCard-like layout)
              Expanded(
                child: MediaCard(
                  item: item,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DownloadOptionsSheet(item: item),
                  ),
                ),
              ),
              // Favorite toggle
              IconButton(
                icon: Icon(
                  ref.read(historyServiceProvider).isFavorite(item.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  await ref.read(historyServiceProvider).toggleFavorite(item);
                  ref.invalidate(favoritesProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
