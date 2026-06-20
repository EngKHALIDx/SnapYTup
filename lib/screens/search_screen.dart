import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/youtube_service.dart';
import '../widgets/media_row.dart';
import 'download_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;
  List<MediaItem> _results = [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    _focus.unfocus();
    try {
      final svc = YouTubeService();
      final items = await svc.search(q.trim(), limit: 30);
      svc.dispose();
      if (!mounted) return;
      setState(() {
        _results = items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar — iOS style
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.search, size: 18, color: Color(0xFF8E8E93)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _search,
                              decoration: const InputDecoration(
                                hintText: 'فيديو، فنان، أو رابط',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() {
                                _controller.clear();
                                _results = [];
                              }),
                              child: const Icon(CupertinoIcons.clear_thick,
                                  size: 16, color: Color(0xFF8E8E93)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_searching) return const Center(child: CupertinoActivityIndicator(radius: 14));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تعذر البحث:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFF3B30)),
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 56, color: const Color(0xFF8E8E93).withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('ابحث عن أي فيديو', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('اكتب كلمة بحث أو الصق رابط يوتيوب',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length + 1,
      separatorBuilder: (_, __) => const Divider(indent: 132, endIndent: 20),
      itemBuilder: (context, i) {
        if (i == _results.length) return const SizedBox(height: 80);
        final item = _results[i];
        return MediaRow(
          item: item,
          onTap: () => _showSheet(item),
          trailing: GestureDetector(
            onTap: () => _showSheet(item),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.arrow_down, color: Colors.white, size: 18),
            ),
          ),
        );
      },
    );
  }

  void _showSheet(MediaItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadSheet(item: item),
    );
  }
}
