import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/services/download_manager.dart';
import '../../../data/repositories/youtube_repository.dart';

/// Lets the user enqueue many videos at once (a YouTube playlist or a
/// multi-select batch). Calls [DownloadManager.enqueue] for each item.
class BatchDownloadController extends StateNotifier<BatchDownloadState> {
  BatchDownloadController(this._downloads, this._yt) : super(const BatchDownloadState());

  final DownloadManager _downloads;
  final YouTubeRepository _yt;

  /// Add a single item to the pending batch (does not start downloads).
  void add(MediaItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  /// Remove an item from the pending batch.
  void remove(MediaItem item) {
    state = state.copyWith(items: state.items.where((m) => m.id != item.id).toList());
  }

  /// Clear the pending batch.
  void clear() {
    state = state.copyWith(items: const []);
  }

  /// Start downloading all items in the batch using the same quality/format.
  /// For YouTube items without a direct [streamUrl], we resolve the manifest
  /// first (best muxed stream by default, or best audio if [audioOnly]).
  Future<List<String>> start({
    String quality = '720p',
    bool audioOnly = false,
  }) async {
    final taskIds = <String>[];
    for (final item in state.items) {
      String? streamUrl = item.streamUrl;
      if (streamUrl == null && item.platform == MediaPlatform.youtube) {
        streamUrl = await _yt.resolveStreamUrl(item.id, audioOnly: audioOnly);
      }
      if (streamUrl == null) continue;
      final id = await _downloads.enqueue(
        media: item.copyWith(streamUrl: streamUrl),
        quality: audioOnly ? 'audio' : quality,
        format: audioOnly ? 'm4a' : 'mp4',
        extractAudio: audioOnly,
      );
      taskIds.add(id);
    }
    clear();
    return taskIds;
  }
}

class BatchDownloadState {
  const BatchDownloadState({this.items = const []});
  final List<MediaItem> items;

  BatchDownloadState copyWith({List<MediaItem>? items}) =>
      BatchDownloadState(items: items ?? this.items);
}

/// Riverpod provider.
final batchDownloadProvider =
    StateNotifierProvider<BatchDownloadController, BatchDownloadState>((ref) {
  final downloads = ref.watch(downloadManagerProvider.notifier);
  final yt = ref.watch(youTubeRepoProvider);
  return BatchDownloadController(downloads, yt);
});
