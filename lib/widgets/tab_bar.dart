import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class AppTabBar extends ConsumerWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _Tab(
                    icon: CupertinoIcons.search,
                    label: 'بحث',
                    isSelected: selected == 0,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                  ),
                  _Tab(
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    label: 'تنزيلات',
                    isSelected: selected == 1,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                  ),
                  _Tab(
                    icon: CupertinoIcons.folder_fill,
                    label: 'مكتبتي',
                    isSelected: selected == 2,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
