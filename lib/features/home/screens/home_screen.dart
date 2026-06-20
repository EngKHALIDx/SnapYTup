import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/models/category_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../widgets/category_grid.dart';
import '../widgets/daily_picks_section.dart';

/// Home screen — Snaptube-style: top search bar + platform shortcuts grid +
/// categories + daily picks. The platform shortcuts row sits below the AppBar
/// and acts as the fastest way to jump to a platform's mobile site in the
/// Browser tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              AppConfig.appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: open notifications
            },
          ),
        ],
      ),
      body: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroBanner()),
          SliverToBoxAdapter(child: _PlatformShortcuts()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(child: CategoryGrid(categories: homeCategories),),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Daily Picks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(child: DailyPicksSection()),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Big tappable banner at the top — points users to the browser.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
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
                    const Text(
                      'Download from any platform',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'YouTube · TikTok · Instagram · Facebook · Twitter',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-launch row of platform icons — tapping one opens the platform's
/// mobile site in the Browser tab.
class _PlatformShortcuts extends ConsumerWidget {
  const _PlatformShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: AppConfig.platforms.length,
        itemBuilder: (context, i) {
          final p = AppConfig.platforms[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                // Switch to Browser tab.
                ref.read(selectedTabProvider.notifier).state = 2;
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Color(p.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        p.icon,
                        style: TextStyle(
                          fontSize: 26,
                          color: Color(p.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
