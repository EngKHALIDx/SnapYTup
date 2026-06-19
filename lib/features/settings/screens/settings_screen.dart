import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/services/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/repositories/library_repository.dart';

/// Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Clear cache'),
            subtitle: const Text('Remove downloaded files'),
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
