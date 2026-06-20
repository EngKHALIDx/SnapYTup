import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_cleanup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Storage cleanup screen — shows large files / cache / WhatsApp backups
/// and lets the user delete them to free up space (Snaptube-style).
class StorageCleanupScreen extends ConsumerStatefulWidget {
  const StorageCleanupScreen({super.key});

  @override
  ConsumerState<StorageCleanupScreen> createState() => _StorageCleanupScreenState();
}

class _StorageCleanupScreenState extends ConsumerState<StorageCleanupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<CleanupCandidate> _junk = [];
  List<CleanupCandidate> _own = [];
  bool _loading = true;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => _selected.clear());
    _scan();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final svc = ref.read(storageCleanupProvider);
    final junk = await svc.scanJunk();
    final own = await svc.scanOwnDownloads();
    if (!mounted) return;
    setState(() {
      _junk = junk;
      _own = own;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage cleanup'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Junk files'),
            Tab(text: 'My downloads'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_junk),
                _buildList(_own),
              ],
            ),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
              label: Text(_selected.length == 1
                  ? 'Delete 1 file'
                  : 'Delete ${_selected.length} files'),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildList(List<CleanupCandidate> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cleaning_services_outlined, size: 64, color: AppColors.textSecondaryDark),
            const SizedBox(height: 8),
            const Text('Nothing to clean.'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _scan, child: const Text('Refresh')),
          ],
        ),
      );
    }
    final totalBytes = items.fold<int>(0, (a, c) => a + c.sizeBytes);
    return Column(
      children: [
        ListTile(
          title: Text('${items.length} items · ${FormatUtils.bytes(totalBytes)} total'),
          trailing: TextButton(
            onPressed: () => setState(() {
              if (_selected.length == items.length) {
                _selected.clear();
              } else {
                _selected.addAll(items.map((c) => c.path));
              }
            }),
            child: Text(_selected.length == items.length ? 'Deselect all' : 'Select all'),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              final selected = _selected.contains(c.path);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(c.path);
                  } else {
                    _selected.remove(c.path);
                  }
                }),
                title: Text(c.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${c.label} · ${FormatUtils.bytes(c.sizeBytes)} · ${FormatUtils.timeAgo(c.modified)}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSelected() async {
    final toDelete = _junk.where((c) => _selected.contains(c.path)).toList() +
        _own.where((c) => _selected.contains(c.path)).toList();
    if (toDelete.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete files?'),
        content: Text('This will permanently delete ${toDelete.length} file(s). '
            'Total size: ${FormatUtils.bytes(toDelete.fold<int>(0, (a, c) => a + c.sizeBytes))}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final freed = await ref.read(storageCleanupProvider).delete(toDelete);
    setState(_selected.clear);
    await _scan();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Freed ${FormatUtils.bytes(freed)} of storage.')),
    );
  }
}
