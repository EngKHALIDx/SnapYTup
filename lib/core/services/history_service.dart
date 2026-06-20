import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// Persists the user's watch history and download history locally using
/// SharedPreferences (each entry is a JSON-encoded MediaItem snapshot).
class HistoryService {
  HistoryService(this._prefs);

  final SharedPreferences _prefs;

  static const _watchKey = 'history_watch';
  static const _downloadKey = 'history_download';
  static const _searchKey = 'history_search';
  static const _favoritesKey = 'history_favorites';
  static const _maxEntries = 200;

  // ---------------------------------------------------------------------------
  // Watch history (videos the user opened)
  // ---------------------------------------------------------------------------

  List<MediaItem> getWatchHistory() => _readItems(_watchKey);

  Future<void> addToWatchHistory(MediaItem item) =>
      _addItem(_watchKey, item);

  Future<void> clearWatchHistory() => _prefs.remove(_watchKey);

  // ---------------------------------------------------------------------------
  // Download history
  // ---------------------------------------------------------------------------

  List<MediaItem> getDownloadHistory() => _readItems(_downloadKey);

  Future<void> addToDownloadHistory(MediaItem item) =>
      _addItem(_downloadKey, item);

  Future<void> clearDownloadHistory() => _prefs.remove(_downloadKey);

  // ---------------------------------------------------------------------------
  // Search history (text queries)
  // ---------------------------------------------------------------------------

  List<String> getSearchHistory() {
    final raw = _prefs.getStringList(_searchKey) ?? [];
    return raw.take(_maxEntries).toList();
  }

  Future<void> addToSearchHistory(String query) async {
    final list = getSearchHistory();
    list.insert(0, query);
    // Dedupe + cap.
    final deduped = <String>[];
    for (final q in list) {
      if (!deduped.contains(q)) deduped.add(q);
      if (deduped.length >= _maxEntries) break;
    }
    await _prefs.setStringList(_searchKey, deduped);
  }

  Future<void> removeFromSearchHistory(String query) async {
    final list = getSearchHistory()..remove(query);
    await _prefs.setStringList(_searchKey, list);
  }

  Future<void> clearSearchHistory() => _prefs.remove(_searchKey);

  // ---------------------------------------------------------------------------
  // Favorites / Bookmarks
  // ---------------------------------------------------------------------------

  List<MediaItem> getFavorites() => _readItems(_favoritesKey);

  Future<void> toggleFavorite(MediaItem item) async {
    final list = getFavorites();
    final exists = list.any((m) => m.id == item.id);
    if (exists) {
      await _writeItems(_favoritesKey, list.where((m) => m.id != item.id).toList());
    } else {
      await _addItem(_favoritesKey, item);
    }
  }

  bool isFavorite(String id) => getFavorites().any((m) => m.id == id);

  // ---------------------------------------------------------------------------
  // Internal JSON helpers
  // ---------------------------------------------------------------------------

  List<MediaItem> _readItems(String key) {
    final raw = _prefs.getStringList(key) ?? [];
    return raw
        .map((s) {
          try {
            return MediaItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<MediaItem>()
        .toList();
  }

  Future<void> _writeItems(String key, List<MediaItem> items) async {
    final raw = items.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(key, raw);
  }

  Future<void> _addItem(String key, MediaItem item) async {
    final list = _readItems(key);
    list.insert(0, item);
    // Dedupe by id, cap to _maxEntries.
    final seen = <String>{};
    final deduped = <MediaItem>[];
    for (final m in list) {
      if (seen.contains(m.id)) continue;
      seen.add(m.id);
      deduped.add(m);
      if (deduped.length >= _maxEntries) break;
    }
    await _writeItems(key, deduped);
  }
}

/// Riverpod provider — must be overridden in ProviderScope with a real
/// SharedPreferences instance.
final historyServiceProvider = Provider<HistoryService>((ref) {
  throw UnimplementedError('historyServiceProvider must be overridden');
});

/// Convenience providers exposing ready-to-read lists.
final watchHistoryProvider = Provider<List<MediaItem>>((ref) {
  return ref.watch(historyServiceProvider).getWatchHistory();
});

final downloadHistoryProvider = Provider<List<MediaItem>>((ref) {
  return ref.watch(historyServiceProvider).getDownloadHistory();
});

final searchHistoryProvider = Provider<List<String>>((ref) {
  return ref.watch(historyServiceProvider).getSearchHistory();
});

final favoritesProvider = Provider<List<MediaItem>>((ref) {
  return ref.watch(historyServiceProvider).getFavorites();
});
