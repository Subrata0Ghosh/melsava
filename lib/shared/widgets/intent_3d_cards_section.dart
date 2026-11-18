import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'intent_3d_icons.dart';

class IntentItemData {
  final String name;
  final String key;
  final String shortTag;
  final Widget Function({double size}) iconBuilder;
  final List<Color> bgGradient;
  final List<Color> darkBgGradient;
  final Color accentColor;
  final Color shadowColor;

  const IntentItemData({
    required this.name,
    required this.key,
    required this.shortTag,
    required this.iconBuilder,
    required this.bgGradient,
    required this.darkBgGradient,
    required this.accentColor,
    required this.shadowColor,
  });
}

/// ─────────────────────────────────────────────────────────────────────────────
/// VOLUMETRIC 3D "EXPLORE BY INTENT" SECTION
/// Features claymorphic / 3D skeuomorphic cards with custom-crafted volumetric
/// 3D icons, specular light highlights, tactile contact shadows, and haptic feedback.
/// ─────────────────────────────────────────────────────────────────────────────
class Intent3DCardsSection extends StatelessWidget {
  final String? selectedIntent;
  final ValueChanged<String?> onIntentSelected;
  final VoidCallback? onSeeAllTap;

  const Intent3DCardsSection({
    super.key,
    required this.selectedIntent,
    required this.onIntentSelected,
    this.onSeeAllTap,
  });

  static final List<IntentItemData> intents = [
    IntentItemData(
      name: 'Friendship',
      key: 'Friendship',
      shortTag: 'Connect',
      iconBuilder: ({double size = 38}) => Friendship3DIcon(size: size),
      bgGradient: const [
        Color(0xFFF3F8FF),
        Color(0xFFE2EFFF),
        Color(0xFFCCE4FF),
      ],
      darkBgGradient: const [Color(0xFF1A273A), Color(0xFF131D2C)],
      accentColor: const Color(0xFF0288D1),
      shadowColor: const Color(0xFF0288D1),
    ),
    IntentItemData(
      name: 'Activity\nPartner',
      key: 'Activity Partner',
      shortTag: 'Hobbies',
      iconBuilder: ({double size = 38}) => ActivityPartner3DIcon(size: size),
      bgGradient: const [
        Color(0xFFFFF2F6),
        Color(0xFFFFDFEB),
        Color(0xFFFFCADE),
      ],
      darkBgGradient: const [Color(0xFF331926), Color(0xFF221019)],
      accentColor: const Color(0xFFE91E63),
      shadowColor: const Color(0xFFE91E63),
    ),
    IntentItemData(
      name: 'Dating',
      key: 'Dating',
      shortTag: 'Sparks',
      iconBuilder: ({double size = 38}) => Dating3DIcon(size: size),
      bgGradient: const [
        Color(0xFFF0FDF5),
        Color(0xFFD8FCE5),
        Color(0xFFBDF9D3),
      ],
      darkBgGradient: const [Color(0xFF152C22), Color(0xFF0E1E17)],
      accentColor: const Color(0xFF00BFA5),
      shadowColor: const Color(0xFF00BFA5),
    ),
    IntentItemData(
      name: 'Serious\nRelationship',
      key: 'Serious Relationship',
      shortTag: 'Long Term',
      iconBuilder: ({double size = 38}) =>
          SeriousRelationship3DIcon(size: size),
      bgGradient: const [
        Color(0xFFFFF9E8),
        Color(0xFFFFEFC7),
        Color(0xFFFFDF9E),
      ],
      darkBgGradient: const [Color(0xFF332916), Color(0xFF231B0E)],
      accentColor: const Color(0xFFFF8F00),
      shadowColor: const Color(0xFFFF8F00),
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
        // ── Header: Title & Action Link ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Explore by Intent',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (selectedIntent != null) {
                    onIntentSelected(null);
                  } else {
                    onSeeAllTap?.call();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedIntent != null
                        ? (isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple)
                              .withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedIntent != null ? 'Clear filter ✕' : 'See all →',
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

        // ── 3D Claymorphic Intent Cards List (Compact Squircle Proportions) ──
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: intents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = intents[index];
              final isSelected = selectedIntent == item.key;

              return _Intent3DCardItem(
                item: item,
                isSelected: isSelected,
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onIntentSelected(isSelected ? null : item.key);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Intent3DCardItem extends StatefulWidget {
  final IntentItemData item;
  final bool isSelected;
  final bool isDark;
  final Color primaryTextColor;
  final VoidCallback onTap;

  const _Intent3DCardItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.primaryTextColor,
    required this.onTap,
  });

  @override
  State<_Intent3DCardItem> createState() => _Intent3DCardItemState();
}

class _Intent3DCardItemState extends State<_Intent3DCardItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : (isSelected ? 1.025 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 86,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? item.darkBgGradient : item.bgGradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? item.accentColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.90)),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              // Colored ambient glow shadow
              BoxShadow(
                color: item.shadowColor.withValues(
                  alpha: isSelected
                      ? (isDark ? 0.40 : 0.30)
                      : (isDark ? 0.20 : 0.14),
                ),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 5 : 3),
              ),
              // Crisp dark contact shadow underneath
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Top-Left Specular Surface Sheen ───────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.08 : 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Selected Active Indicator Check Dot ───────────────────────
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),

              // ── Main Content: 3D Volumetric Icon + Bold Typography ────────
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Volumetric 3D Icon with gentle float animation
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(
                            0,
                            isSelected ? -2 : 0,
                            0,
                          ),
                          child: item.iconBuilder(size: 38),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Title (Strictly centered across full card width)
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.2,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w800,
                            color: isDark ? Colors.white : item.accentColor,
                            height: 1.12,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
