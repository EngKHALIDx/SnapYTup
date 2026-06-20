import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/repositories/library_repository.dart';
import '../../history/screens/history_screen.dart';
import '../../playlists/screens/playlists_screen.dart';
import '../../storage_cleanup/screens/storage_cleanup_screen.dart';
import '../../vault/screens/vault_unlock_screen.dart';

/// Settings screen — Snaptube-style: appearance, downloads, vault, storage
/// cleanup, about + in-app update banner.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _UpdateBanner(),
          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            trailing: Switch(
              value: theme == ThemeMode.dark ||
                  (theme == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark),
              onChanged: (_) => ref.read(themeControllerProvider.notifier).toggle(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto_outlined),
            title: const Text('Follow system'),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: theme == ThemeMode.system ? AppColors.primary : null,
              onPressed: () => ref.read(themeControllerProvider.notifier).set(ThemeMode.system),
            ),
          ),
          const Divider(),
          _SectionHeader('Downloads'),
          FutureBuilder<String>(
            future: _downloadsPath(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Save location'),
              subtitle: Text(snap.data ?? 'Loading…'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await StorageUtils.openManageAllFilesSettings();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined),
            title: const Text('Default quality'),
            subtitle: const Text('720p'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: show quality picker
            },
          ),
          const Divider(),
          _SectionHeader('Library'),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.info),
            title: const Text('History'),
            subtitle: const Text('Watched, downloaded, favorites'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play, color: AppColors.secondary),
            title: const Text('Playlists'),
            subtitle: const Text('Custom music / video collections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PlaylistsScreen()),
            ),
          ),
          const Divider(),
          _SectionHeader('Privacy & Storage'),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('Vault'),
            subtitle: const Text('Hide private downloads behind a PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const VaultUnlockScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.info),
            title: const Text('Storage cleanup'),
            subtitle: const Text('Free up space by removing junk files'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StorageCleanupScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Clear MediaGrab cache'),
            subtitle: const Text('Remove all downloaded videos and music'),
            onTap: () => _confirmClear(context, ref),
          ),
          const Divider(),
          _SectionHeader('About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final info = snap.data;
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppConfig.appName),
                subtitle: Text('Version ${info?.version ?? AppConfig.version} '
                    '(${info?.buildNumber ?? AppConfig.buildNumber})'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source on GitHub'),
            subtitle: const Text('github.com/EngKHALIDx/SnapYTup'),
            onTap: () {
              // launchUrl could be used here, omitted to keep deps lean.
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Check for updates'),
            onTap: () => ref.invalidate(updateCheckProvider),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<String> _downloadsPath() async {
    final dir = await StorageUtils.downloadsRoot();
    return dir.path;
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all downloads?'),
        content: const Text('This will permanently delete all videos and music '
            'stored in MediaGrab/Videos and MediaGrab/Music.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(libraryRepoProvider);
              final items = await repo.listAllDownloads();
              for (final item in items) {
                await repo.delete(item.sourceUrl);
              }
              ref.invalidate(videosProvider);
              ref.invalidate(musicProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared.')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.1,
          ),
        ),
      );
}

/// Banner shown at the top of Settings when a newer version is available.
class _UpdateBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateCheckProvider);
    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null || !data.updateAvailable) return const SizedBox.shrink();
        return Material(
          color: AppColors.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.system_update, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Update available',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text('v${data.currentVersion} → v${data.latestVersion}'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Could open browser to GitHub releases.
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
