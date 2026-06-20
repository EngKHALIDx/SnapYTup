import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/media_card.dart';
import '../../search/widgets/youtube_search_notifier.dart';

/// "Daily Picks" horizontal list with iOS-style card design.
class DailyPicksSection extends ConsumerWidget {
  const DailyPicksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(youtubeSearchProvider('trending music 2026'));
    return SizedBox(
      height: 220,
      child: trending.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => _ErrorBox(message: e.toString()),
        data: (items) {
          if (items.isEmpty) return const _EmptyBox();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 200,
                child: MediaCard(
                  item: item,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        duration: const Duration(milliseconds: 600),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load picks.\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.systemRed, fontSize: 13),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No picks today.'));
  }
}
