import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_config.dart';
import 'core/services/clipboard_watcher_service.dart';
import 'core/services/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/downloader/screens/download_queue_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'widgets/app_bottom_nav.dart';

/// Root widget of the MediaGrab app.
class MediaGrabApp extends ConsumerStatefulWidget {
  const MediaGrabApp({super.key});

  @override
  ConsumerState<MediaGrabApp> createState() => _MediaGrabAppState();
}

class _MediaGrabAppState extends ConsumerState<MediaGrabApp> {
  @override
  void initState() {
    super.initState();
    // Start watching the clipboard for video URLs (Snaptube-style).
    Future.microtask(() {
      final watcher = ref.read(clipboardWatcherProvider);
      watcher.start((url) {
        if (!mounted) return;
        ref.read(detectedUrlProvider.notifier).state = url;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: const Text('Video link detected in clipboard'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                ref.read(selectedTabProvider.notifier).state = 2; // Browser tab
              },
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // RTL + Arabic localization (Snaptube is RTL Arabic-first)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const _Shell(),
    );
  }
}

/// Holds the bottom-nav and swaps the active tab body.
/// Uses a Stack with Offstage so each tab preserves its scroll position
/// when the user switches away (iOS pattern).
class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      body: Stack(
        children: [
          Offstage(offstage: tab != 0, child: const SearchScreen()),
          Offstage(offstage: tab != 1, child: const DownloadQueueScreen()),
          Offstage(offstage: tab != 2, child: const SettingsScreen()),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
