import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/downloads_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'theme.dart';
import 'widgets/tab_bar.dart';

class MediaGrabApp extends ConsumerWidget {
  const MediaGrabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MediaGrab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const _Shell(),
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    final titles = ['بحث', 'تنزيلات', 'مكتبتي'];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(titles[tab], style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: Stack(
        children: [
          Offstage(offstage: tab != 0, child: const SearchScreen()),
          Offstage(offstage: tab != 1, child: const DownloadsScreen()),
          Offstage(offstage: tab != 2, child: const LibraryScreen()),
        ],
      ),
      bottomNavigationBar: const AppTabBar(),
    );
  }
}
