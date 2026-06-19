import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';

/// Index of the currently selected bottom nav tab.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Snaptube-style bottom navigation bar with 5 tabs.
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  static const _items = <BottomNavItem>[
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    BottomNavItem(icon: Icons.language_outlined, activeIcon: Icons.language, label: 'Browser'),
    BottomNavItem(icon: Icons.video_library_outlined, activeIcon: Icons.video_library, label: 'Library'),
    BottomNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,
      destinations: [
        for (final item in _items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
            label: item.label,
          ),
      ],
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}

class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
