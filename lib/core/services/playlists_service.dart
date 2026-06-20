import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';

/// Persists named playlists of [MediaItem]s in SharedPreferences.
/// Snaptube lets users create custom playlists to organize their music
/// and downloaded videos — this service replicates that.
class PlaylistsService {
  PlaylistsService(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'playlists';

  /// All playlists, ordered by last-modified.
  List<Playlist> getAll() {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return Playlist.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Playlist>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Create a new empty playlist. Returns its id.
  Future<String> create({required String name}) async {
    final id = const Uuid().v4();
    final list = getAll();
    list.insert(0, Playlist(id: id, name: name, items: const [], updatedAt: DateTime.now()));
    await _save(list);
    return id;
  }

  /// Rename a playlist.
  Future<void> rename(String id, String newName) async {
    final list = getAll();
    final idx = list.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(name: newName, updatedAt: DateTime.now());
    await _save(list);
  }

  /// Delete a playlist.
  Future<void> delete(String id) async {
    final list = getAll().where((p) => p.id != id).toList();
    await _save(list);
  }

  /// Append a [MediaItem] to a playlist.
  Future<void> addItem(String playlistId, MediaItem item) async {
    final list = getAll();
    final idx = list.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final items = [...list[idx].items, item];
    list[idx] = list[idx].copyWith(items: items, updatedAt: DateTime.now());
    await _save(list);
  }

  /// Remove the item at [index] from a playlist.
  Future<void> removeItemAt(String playlistId, int index) async {
    final list = getAll();
    final idx = list.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final items = [...list[idx].items]..removeAt(index);
    list[idx] = list[idx].copyWith(items: items, updatedAt: DateTime.now());
    await _save(list);
  }

  /// Clear all playlists.
  Future<void> clear() => _prefs.remove(_key);

  Future<void> _save(List<Playlist> list) async {
    final raw = list.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_key, raw);
  }
}

/// One named playlist.
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.items,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<MediaItem> items;
  final DateTime updatedAt;

  Playlist copyWith({
    String? id,
    String? name,
    List<MediaItem>? items,
    DateTime? updatedAt,
  }) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        items: items ?? this.items,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((m) => m.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Riverpod provider.
final playlistsServiceProvider = Provider<PlaylistsService>((ref) {
  throw UnimplementedError('playlistsServiceProvider must be overridden');
});

/// Convenience: live list of all playlists.
final playlistsProvider = Provider<List<Playlist>>((ref) {
  return ref.watch(playlistsServiceProvider).getAll();
});
