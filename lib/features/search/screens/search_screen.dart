import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../widgets/media_thumbnail.dart';
import '../../downloader/screens/download_options_sheet.dart';
import '../../downloader/widgets/batch_download_controller.dart';
import '../widgets/youtube_search_notifier.dart';

/// Full-screen search experience.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<String> _recent = [];

  static const _suggestions = <String>[
    'trending music 2026',
    'arabic music',
    'funny cats',
    'flutter tutorial',
    'mr beast',
    'football highlights',
    'movie trailers 2026',
    'cooking recipes',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recent = [query, ..._recent.where((e) => e != query)].take(8).toList();
    });
    // Persist to global search history.
    ref.read(historyServiceProvider).addToSearchHistory(query.trim());
    ref.invalidate(searchHistoryProvider);
    ref.read(searchQueryProvider.notifier).state = query.trim();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchField(
          controller: _controller,
          focus: _focus,
          onSubmitted: _submit,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: () {
              // TODO: speech-to-text
            },
          ),
        ],
      ),
      body: query.isEmpty ? _buildSuggestions(isDark) : _buildResults(query),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(_recent.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map((q) => _SuggestionChip(
                      label: q,
                      onTap: () => _submit(q),
                      isRecent: true,
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Trending',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((q) => _SuggestionChip(label: q, onTap: () => _submit(q)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResults(String query) {
    final async = ref.watch(youtubeSearchProvider(query));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(youtubeSearchProvider(query)),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Search failed: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No results.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return _SearchResultTile(
                item: item,
                onTap: () => _showOptionsSheet(item),
                onLongPress: () {
                  // Long-press adds to the batch download queue.
                  ref.read(batchDownloadProvider.notifier).add(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to batch · ${ref.read(batchDownloadProvider).items.length} item(s)'),
                      action: SnackBarAction(
                        label: 'Start batch',
                        onPressed: () async {
                          await ref.read(batchDownloadProvider.notifier).start();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Batch download started.')),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showOptionsSheet(item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DownloadOptionsSheet(item: item),
    );
  }
}

/// Search field with rounded background.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focus,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search videos, music…',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                ),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

/// Suggestion chip with a small leading icon.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
    this.isRecent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isRecent;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        isRecent ? Icons.history : Icons.trending_up,
        size: 16,
        color: AppColors.primary,
      ),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// One search result row with thumbnail + meta + download button.
class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: SizedBox(
        width: 120,
        height: 68,
        child: Stack(
          children: [
            Positioned.fill(child: MediaThumbnail(url: item.thumbnailUrl, borderRadius: 8)),
            if (item.duration != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    FormatUtils.duration(item.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            // Snaptube-pattern: small black download arrow overlaid on thumbnail corner.
            Positioned(
              left: 4,
              bottom: 4,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        item.title ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (item.author != null) item.author,
          if (item.viewCount != null) FormatUtils.views(item.viewCount),
          if (item.uploadDate != null) FormatUtils.timeAgo(item.uploadDate),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download_for_offline_outlined, color: AppColors.primary),
        onPressed: onTap,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
