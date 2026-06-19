import 'dart:ui' show Color;

/// A category on the home screen (Music, Sports, Movies, …).
class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.colorValue,
    this.query,
  });

  final String id;
  final String title;
  final String icon;          // emoji / short glyph
  final int colorValue;       // ARGB int
  final String? query;        // search query used when tapped

  Color get color => Color(colorValue);
}

/// Hardcoded home categories (Snaptube-style).
const List<CategoryItem> homeCategories = [
  CategoryItem(id: 'music',     title: 'Music',     icon: '🎵', colorValue: 0xFFFF6B6B, query: 'music'),
  CategoryItem(id: 'sports',    title: 'Sports',    icon: '⚽', colorValue: 0xFF4ECDC4, query: 'sports highlights'),
  CategoryItem(id: 'movies',    title: 'Movies',    icon: '🎬', colorValue: 0xFFFFD93D, query: 'movie trailer'),
  CategoryItem(id: 'gaming',    title: 'Gaming',    icon: '🎮', colorValue: 0xFF95D5B2, query: 'gaming'),
  CategoryItem(id: 'news',      title: 'News',      icon: '📰', colorValue: 0xFFA8DADC, query: 'news'),
  CategoryItem(id: 'comedy',    title: 'Comedy',    icon: '😂', colorValue: 0xFFFFB4A2, query: 'comedy'),
  CategoryItem(id: 'tech',      title: 'Tech',      icon: '💻', colorValue: 0xFFBDB2FF, query: 'technology'),
  CategoryItem(id: 'fashion',   title: 'Fashion',   icon: '👗', colorValue: 0xFFFFC8DD, query: 'fashion'),
];
