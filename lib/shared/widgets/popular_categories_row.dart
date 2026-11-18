import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'category_3d_icons.dart';

class CategoryItemData {
  final String label;
  final String categoryKey;
  final IconData icon;
  final List<Color> bgGradient;
  final List<Color> iconGradient;
  final Color shadowColor;

  const CategoryItemData({
    required this.label,
    required this.categoryKey,
    required this.icon,
    required this.bgGradient,
    required this.iconGradient,
    required this.shadowColor,
  });
}

/// Popular Categories squircle bar cloned directly from Image 2 & Image 3 Screen 5:
/// - Soft pastel glassmorphic squircles with subtle border and elevation
/// - Rich multi-color icons matching Social, Sports, Travel, Arts & Culture, Wellness
/// - Bold typography and smooth micro-interaction feedback
class PopularCategoriesRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onSeeAllTap;

  const PopularCategoriesRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.onSeeAllTap,
  });

  static const List<CategoryItemData> categories = [
    CategoryItemData(
      label: 'Social',
      categoryKey: 'Social',
      icon: Icons.people_alt_rounded,
      bgGradient: [Color(0xFFFFEDB8), Color(0xFFCEF1FF)],
      iconGradient: [Color(0xFF0072FF), Color(0xFF00C6FF)],
      shadowColor: Color(0x330072FF),
    ),
    CategoryItemData(
      label: 'Sports',
      categoryKey: 'Sports',
      icon: Icons.sports_tennis_rounded,
      bgGradient: [Color(0xFFFFF0E5), Color(0xFFFFD6C2)],
      iconGradient: [Color(0xFFFF5E36), Color(0xFFFF9F43)],
      shadowColor: Color(0x33FF5E36),
    ),
    CategoryItemData(
      label: 'Travel',
      categoryKey: 'Outdoors',
      icon: Icons.landscape_rounded,
      bgGradient: [Color(0xFFF6EEFF), Color(0xFFFFE6D5)],
      iconGradient: [Color(0xFFFF9800), Color(0xFFFFC107)],
      shadowColor: Color(0x33FF9800),
    ),
    CategoryItemData(
      label: 'Arts & Culture',
      categoryKey: 'Arts & Culture',
      icon: Icons.palette_rounded,
      bgGradient: [Color(0xFFF7E6FF), Color(0xFFECD4FF)],
      iconGradient: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      shadowColor: Color(0x339C27B0),
    ),
    CategoryItemData(
      label: 'Wellness',
      categoryKey: 'Wellness',
      icon: Icons.spa_rounded,
      bgGradient: [Color(0xFFEDE7F6), Color(0xFFDED2F8)],
      iconGradient: [Color(0xFF673AB7), Color(0xFF512DA8)],
      shadowColor: Color(0x33673AB7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "Popular Categories" + "See all →"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Categories',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: primaryTextColor,
                ),
              ),
              if (selectedCategory != 'All')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onCategorySelected('All');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Clear filter ✕',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.brightViolet
                                : AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSeeAllTap?.call();
                      },
                      child: Text(
                        'See all →',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSeeAllTap?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      'See all →',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal Row of Squircles
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCategory == cat.categoryKey;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(isSelected ? 'All' : cat.categoryKey);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Squircle Container with Soft Pastel Gradient & Glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF261F36),
                                  const Color(0xFF1E172C),
                                ]
                              : cat.bgGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(
                                  0xFFF59E0B,
                                ) // Gold Shimmer Active Accent
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.85)),
                          width: isSelected ? 2.2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFFF59E0B).withValues(
                                    alpha: 0.40,
                                  ) // Warm Gold Halo
                                : (isDark
                                      ? Colors.black26
                                      : cat.shadowColor.withValues(
                                          alpha: 0.16,
                                        )),
                            blurRadius: isSelected ? 14 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Category3DIcon(
                          categoryKey: cat.categoryKey,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Label below Squircle
                    SizedBox(
                      width: 66,
                      child: Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? (isDark
                                    ? AppColors.brightViolet
                                    : AppColors.primaryPurple)
                              : primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
