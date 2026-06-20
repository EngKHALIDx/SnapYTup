import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/library_service.dart';
import '../widgets/media_row.dart';
import 'player_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // iOS-style segmented control
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFE5E5EA).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  unselectedLabelColor: const Color(0xFF8E8E93),
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'فيديو'),
                    Tab(text: 'موسيقى'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _list(ref.watch(videosProvider), isAudio: false),
                  _list(ref.watch(musicProvider), isAudio: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(AsyncValue<List<dynamic>> async, {required bool isAudio}) {
    return async.when(
      loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Color(0xFFFF3B30)))),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.folder, size: 56, color: const Color(0xFF8E8E93).withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('لا يوجد محتوى', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('حمّل فيديو أو مقطع صوتي ليظهر هنا',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const Divider(indent: 132, endIndent: 20),
          itemBuilder: (context, i) {
            if (i == items.length) return const SizedBox(height: 80);
            final item = items[i];
            return MediaRow(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PlayerScreen(
                  filePath: item.sourceUrl,
                  title: item.title,
                  isAudio: isAudio,
                )),
              ),
              trailing: Icon(CupertinoIcons.play_circle, size: 28, color: const Color(0xFF007AFF).withValues(alpha: 0.7)),
            );
          },
        );
      },
    );
  }
}
