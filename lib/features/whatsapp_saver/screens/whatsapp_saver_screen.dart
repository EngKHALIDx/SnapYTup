import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/repositories/whatsapp_status_repository.dart';
import '../../player/screens/video_player_screen.dart';
import '../widgets/status_grid.dart';

/// WhatsApp Status Saver screen with two tabs: Recent / Saved.
class WhatsAppSaverScreen extends ConsumerStatefulWidget {
  const WhatsAppSaverScreen({super.key});

  @override
  ConsumerState<WhatsAppSaverScreen> createState() => _WhatsAppSaverScreenState();
}

class _WhatsAppSaverScreenState extends ConsumerState<WhatsAppSaverScreen>
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
      appBar: AppBar(
        title: const Text('WhatsApp Status'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _RecentTab(),
          _SavedTab(),
        ],
      ),
    );
  }
}

class _RecentTab extends ConsumerWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MediaItem>>(
      future: ref.watch(whatsappStatusRepoProvider).listRecent(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorBox(message: snap.error.toString());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const _EmptyBox();
        return StatusGrid(
          items: items,
          onTap: (item) => _open(context, item),
          onDownload: (item) async {
            final dir = await StorageUtils.whatsappDir();
            await ref.read(whatsappStatusRepoProvider).save(item, dir.path);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status saved.')),
            );
          },
        );
      },
    );
  }
}

class _SavedTab extends ConsumerStatefulWidget {
  const _SavedTab();

  @override
  ConsumerState<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<_SavedTab> {
  Future<List<MediaItem>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    StorageUtils.whatsappDir().then((d) {
      setState(() {
        _future = ref
            .read(whatsappStatusRepoProvider)
            .listSaved(d.path);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const Center(child: CircularProgressIndicator());
    return FutureBuilder<List<MediaItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return _ErrorBox(message: snap.error.toString());
        final items = snap.data ?? [];
        if (items.isEmpty) return const _EmptyBox();
        return StatusGrid(
          items: items,
          onTap: (item) => _open(context, item),
        );
      },
    );
  }
}

void _open(BuildContext context, MediaItem item) {
  if (item.type == MediaType.video) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(filePath: item.sourceUrl, title: item.title),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImageScreen(path: item.sourceUrl),
      ),
    );
  }
}

class _ImageScreen extends StatelessWidget {
  const _ImageScreen({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Image.file(
          io.File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white54),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error: $message\n\nMake sure WhatsApp is installed and storage permission is granted.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondaryDark),
          SizedBox(height: 8),
          Text('No statuses found.'),
          SizedBox(height: 4),
          Text(
            'Open WhatsApp and view some statuses first.',
            style: TextStyle(color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}
