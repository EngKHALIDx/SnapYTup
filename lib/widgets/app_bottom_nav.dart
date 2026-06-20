import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';

/// Index of the currently selected bottom nav tab.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Cupertino-style bottom tab bar with blur effect (iOS UITabBar pattern).
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  static const _items = <_TabItem>[
    _TabItem(icon: CupertinoIcons.search, label: 'بحث'),
    _TabItem(icon: CupertinoIcons.arrow_down_circle_fill, label: 'تنزيلات'),
    _TabItem(icon: CupertinoIcons.settings, label: 'إعدادات'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkSeparator.withValues(alpha: 0.6)
                    : AppColors.lightSeparator.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _TabButton(
                        item: _items[i],
                        isSelected: selected == i,
                        onTap: () => ref.read(selectedTabProvider.notifier).state = i,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _TabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? AppColors.systemBlue : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.systemBlue : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
