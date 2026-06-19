import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_config.dart';
import 'core/services/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/browser/screens/browser_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'widgets/app_bottom_nav.dart';

/// Root widget of the MediaGrab app.
class MediaGrabApp extends ConsumerWidget {
  const MediaGrabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _Shell(),
    );
  }
}

/// Holds the bottom-nav and swaps the active tab body.
class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),
          SearchScreen(),
          BrowserScreen(),
          LibraryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
