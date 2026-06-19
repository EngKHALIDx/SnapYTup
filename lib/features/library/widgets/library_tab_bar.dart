import 'package:flutter/material.dart';

/// Tab bar for the Library screen.
class LibraryTabBar extends StatelessWidget implements PreferredSizeWidget {
  const LibraryTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: const [
        Tab(text: 'Videos'),
        Tab(text: 'Music'),
        Tab(text: 'Downloads'),
      ],
    );
  }
}
