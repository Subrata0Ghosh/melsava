import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'category_3d_icons.dart';

class CategoryOptionItem {
  final String key;
  final String title;
  final String description;
  final String tag;
  final Widget Function({double size}) iconBuilder;
  final List<Color> bgGradient;
  final List<Color> darkBgGradient;
  final Color accentColor;

  const CategoryOptionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.tag,
    required this.iconBuilder,
    required this.bgGradient,
    required this.darkBgGradient,
    required this.accentColor,
  });
}

/// "Explore All Categories" Bottom Sheet
/// Opens when tapping "See all →" in the Popular Categories section on Discover.
class ExploreAllCategoriesSheet extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const ExploreAllCategoriesSheet({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedCategory,
    required ValueChanged<String> onSelectCategory,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExploreAllCategoriesSheet(
        selectedCategory: selectedCategory,
        onSelectCategory: onSelectCategory,
      ),
    );
  }

  @override
  State<ExploreAllCategoriesSheet> createState() =>
      _ExploreAllCategoriesSheetState();
}

class _ExploreAllCategoriesSheetState extends State<ExploreAllCategoriesSheet> {
  late String _selected;

  static final List<CategoryOptionItem> categories = [
    CategoryOptionItem(
      key: 'All',
      title: 'All Categories',
      description:
          'Explore all public gatherings, weekend trips & micro-groups',
      tag: 'All Events',
      iconBuilder: ({double size = 38}) => Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.75,
        color: const Color(0xFF8B5CF6),
      ),
      bgGradient: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
      darkBgGradient: const [Color(0xFF231A38), Color(0xFF171026)],
      accentColor: const Color(0xFF8B5CF6),
    ),
    CategoryOptionItem(
      key: 'Social',
      title: 'Social & Cafés',
      description:
          'Artisan coffee tastings, book discussions & cozy micro-groups',
      tag: 'Cafés • Chats',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Social', size: size),
      bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      darkBgGradient: const [Color(0xFF13281E), Color(0xFF0C1A14)],
      accentColor: const Color(0xFF10B981),
    ),
    CategoryOptionItem(
      key: 'Outdoors',
      title: 'Outdoors & Trekking',
      description:
          'Scenic ridge hikes, mountain trails, sunrise walks & campfires',
      tag: 'Treks • Trails',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Outdoors', size: size),
      bgGradient: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      darkBgGradient: const [Color(0xFF2E2412), Color(0xFF1D170B)],
      accentColor: const Color(0xFFF59E0B),
    ),
    CategoryOptionItem(
      key: 'Sports',
      title: 'Sports & Games',
      description:
          'Badminton doubles, court rallies, table tennis & weekend cycling',
      tag: 'Sports • Fitness',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Sports', size: size),
      bgGradient: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
      darkBgGradient: const [Color(0xFF32141C), Color(0xFF200C12)],
      accentColor: const Color(0xFFF43F5E),
    ),
    CategoryOptionItem(
      key: 'Arts & Culture',
      title: 'Arts & Culture',
      description:
          'Pottery workshops, heritage courtyard walks, painting & live shows',
      tag: 'Art & Pottery',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Arts', size: size),
      bgGradient: const [Color(0xFFFDF4FF), Color(0xFFF5D0FE)],
      darkBgGradient: const [Color(0xFF2E1338), Color(0xFF1C0A23)],
      accentColor: const Color(0xFFD946EF),
    ),
    CategoryOptionItem(
      key: 'Food',
      title: 'Food & Culinary',
      description:
          'Sourdough bread crafting, artisan baking & chef-led tastings',
      tag: 'Baking • Dining',
      iconBuilder: ({double size = 38}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: const Text('🥖', style: TextStyle(fontSize: 26)),
      ),
      bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      darkBgGradient: const [Color(0xFF2E1B0E), Color(0xFF1E1108)],
      accentColor: const Color(0xFFEA580C),
    ),
    CategoryOptionItem(
      key: 'Wellness',
      title: 'Wellness & Mindfulness',
      description:
          'Morning hatha yoga, meditation circles & calming herbal tea sessions',
      tag: 'Yoga • Zen',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Wellness', size: size),
      bgGradient: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
      darkBgGradient: const [Color(0xFF23163E), Color(0xFF160D27)],
      accentColor: const Color(0xFF7C3AED),
    ),
    CategoryOptionItem(
      key: 'Travel',
      title: 'Travel & Day Escapes',
      description:
          'Weekend lake getaways, heritage architecture tours & road trips',
      tag: 'Day Trips',
      iconBuilder: ({double size = 38}) =>
          Category3DIcon(categoryKey: 'Travel', size: size),
      bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      darkBgGradient: const [Color(0xFF14223A), Color(0xFF0C1525)],
      accentColor: const Color(0xFF3B82F6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1E1435);
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : const Color(0xFF7E7394);
    final sheetBg = isDark ? const Color(0xFF1B1528) : const Color(0xFFFAF7F4);
    final borderColor = isDark
        ? const Color(0xFF332A45)
        : const Color(0xFFEDE9FE);

    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.88),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: mutedTextColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brightViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.brightViolet,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore All Categories',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'Pick a theme to filter verified public micro-experiences',
                        style: TextStyle(color: mutedTextColor, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: mutedTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.8, color: borderColor),

          // Category items list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              physics: const ClampingScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selected == cat.key;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selected = cat.key;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark ? cat.darkBgGradient : cat.bgGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? cat.accentColor
                            : (isDark
                                  ? const Color(0xFF332A45)
                                  : const Color(0xFFEDE9FE)),
                        width: isSelected ? 2.0 : 0.9,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cat.accentColor.withValues(alpha: 0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // 3D Category icon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: cat.iconBuilder(size: 32),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 7,
                                runSpacing: 3,
                                children: [
                                  Text(
                                    cat.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cat.accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: cat.accentColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      cat.tag,
                                      style: TextStyle(
                                        color: cat.accentColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9.5,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.description,
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 11.5,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Radio checkmark indicator
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? cat.accentColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? cat.accentColor
                                  : mutedTextColor.withValues(alpha: 0.5),
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brightViolet,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.brightViolet.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSelectCategory(_selected);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      _selected == 'All'
                          ? 'Show All Experiences'
                          : 'Apply Filter ($_selected)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/experiences');
                  },
                  child: Text(
                    'Open Full Experiences Catalog →',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.brightViolet
                          : AppColors.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
