import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/models/category_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../widgets/category_grid.dart';
import '../widgets/daily_picks_section.dart';

/// iOS-style Home screen: large title + blur search field + horizontal
/// platform shortcuts + trending feed + categories grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Large title (iOS pattern)
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 8),
              title: Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          // Search field
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _SearchField(onTap: () {
                ref.read(selectedTabProvider.notifier).state = 1;
              }),
            ),
          ),
          // Platform shortcuts
          SliverToBoxAdapter(child: _PlatformShortcuts(isDark: isDark)),
          // Hero card
          const SliverToBoxAdapter(child: _HeroCard()),
          // Categories section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Browse Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: CategoryGrid(categories: homeCategories)),
          // Daily picks
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Daily Picks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: DailyPicksSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.lightSurfaceAlt.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.search,
                size: 18,
                color: isDark ? AppColors.labelSecondaryDark : AppColors.labelSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search or paste a link',
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary,
                ),
              ),
            ),
            Icon(CupertinoIcons.mic,
                size: 18,
                color: isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary),
          ],
        ),
      ),
    );
  }
}

class _PlatformShortcuts extends StatelessWidget {
  const _PlatformShortcuts({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: AppConfig.platforms.length + 1,
        itemBuilder: (context, i) {
          if (i == AppConfig.platforms.length) {
            return _ShortcutTile(
              icon: CupertinoIcons.square_grid_2x2,
              label: 'All sites',
              color: AppColors.systemBlue,
              isDark: isDark,
              onTap: () => _goToBrowser(context),
            );
          }
          final p = AppConfig.platforms[i];
          return _ShortcutTile(
            icon: _iconForPlatform(p.name),
            label: p.name,
            color: Color(p.color),
            isDark: isDark,
            onTap: () => _goToBrowser(context),
          );
        },
      ),
    );
  }

  void _goToBrowser(BuildContext context) {
    // switch to Browser tab via the Riverpod provider
    final container = ProviderScope.containerOf(context);
    container.read(selectedTabProvider.notifier).state = 2;
  }

  IconData _iconForPlatform(String name) {
    switch (name) {
      case 'YouTube': return CupertinoIcons.play_rectangle_fill;
      case 'TikTok': return CupertinoIcons.music_note;
      case 'Instagram': return CupertinoIcons.camera;
      case 'Facebook': return CupertinoIcons.person_2_fill;
      case 'Twitter': return CupertinoIcons.heart;
      case 'WhatsApp': return CupertinoIcons.chat_bubble_fill;
      default: return CupertinoIcons.globe;
    }
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 144,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.systemIndigo, AppColors.systemBlue],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Download Anything',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Videos & music from 100+ platforms.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.download_circle_fill, color: Colors.white, size: 56),
            ],
          ),
        ),
      ),
    );
  }
}
