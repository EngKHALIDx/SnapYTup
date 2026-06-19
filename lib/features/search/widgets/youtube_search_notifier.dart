import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../data/repositories/youtube_repository.dart';

/// Family provider that performs a YouTube search for the given query.
///
/// The query is cached for the lifetime of the provider, so multiple widgets
/// reading the same query share one network request.
final youtubeSearchProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(youTubeRepoProvider);
  return repo.search(query.trim(), limit: 25);
});

/// Stateful search query (so multiple widgets can react to it).
final searchQueryProvider = StateProvider<String>((ref) => '');
