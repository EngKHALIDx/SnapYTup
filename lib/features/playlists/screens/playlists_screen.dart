import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/playlists_service.dart';
import '../../../core/theme/app_colors.dart';

/// Playlists screen — list all custom playlists with create / rename /
/// delete actions. Tapping a playlist opens its detail (item list).
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createPlaylist(context, ref),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_play, size: 64, color: AppColors.textSecondaryDark),
                  const SizedBox(height: 8),
                  const Text('No playlists yet.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _createPlaylist(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create playlist'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, i) {
                final p = playlists[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.playlist_play, color: Colors.white),
                  ),
                  title: Text(p.name),
                  subtitle: Text('${p.items.length} item(s)'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        _renamePlaylist(context, ref, p);
                      } else if (v == 'delete') {
                        await ref.read(playlistsServiceProvider).delete(p.id);
                        ref.invalidate(playlistsProvider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () {
                    // TODO: open playlist detail
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${p.items.length} item(s) in "${p.name}"')),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await _prompt(context, title: 'New playlist', hint: 'Playlist name');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistsServiceProvider).create(name: name.trim());
    ref.invalidate(playlistsProvider);
  }

  Future<void> _renamePlaylist(BuildContext context, WidgetRef ref, Playlist p) async {
    final name = await _prompt(context, title: 'Rename playlist', hint: 'New name', initial: p.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistsServiceProvider).rename(p.id, name.trim());
    ref.invalidate(playlistsProvider);
  }

  Future<String?> _prompt(
    BuildContext context, {
    required String title,
    required String hint,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
