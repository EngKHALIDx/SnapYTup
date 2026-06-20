import 'package:flutter/material.dart';

import '../../../core/models/category_item.dart';

/// iOS-style 4-column grid of category tiles with circular tinted icons.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.categories});

  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _CategoryTile(item: categories[i]),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item});
  final CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.title),
            duration: const Duration(milliseconds: 600),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
