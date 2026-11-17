import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'intent_3d_icons.dart';

class FullIntentOption {
  final String key;
  final String title;
  final String description;
  final Widget Function({double size}) iconBuilder;
  final List<Color> bgGradient;
  final List<Color> darkBgGradient;
  final Color accentColor;
  final Color shadowColor;

  const FullIntentOption({
    required this.key,
    required this.title,
    required this.description,
    required this.iconBuilder,
    required this.bgGradient,
    required this.darkBgGradient,
    required this.accentColor,
    required this.shadowColor,
  });
}

/// "Explore All Intents" Bottom Sheet
/// Opens when tapping "See all →" in the Explore by Intent section.
class ExploreAllIntentsSheet extends StatefulWidget {
  final String? currentIntent;
  final ValueChanged<String?> onSelectIntent;

  const ExploreAllIntentsSheet({
    super.key,
    required this.currentIntent,
    required this.onSelectIntent,
  });

  static Future<void> show(
    BuildContext context, {
    required String? currentIntent,
    required ValueChanged<String?> onSelectIntent,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExploreAllIntentsSheet(
        currentIntent: currentIntent,
        onSelectIntent: onSelectIntent,
      ),
    );
  }

  @override
  State<ExploreAllIntentsSheet> createState() => _ExploreAllIntentsSheetState();
}

class _ExploreAllIntentsSheetState extends State<ExploreAllIntentsSheet> {
  late String? _selected;

  static final List<FullIntentOption> options = [
    FullIntentOption(
      key: 'Friendship',
      title: 'Friendship',
      description: 'Meet like-minded friends, weekend buddies & coffee chats',
      iconBuilder: ({double size = 42}) => Friendship3DIcon(size: size),
      bgGradient: const [Color(0xFFF3F8FF), Color(0xFFDCEBFF)],
      darkBgGradient: const [Color(0xFF1A273A), Color(0xFF131D2C)],
      accentColor: const Color(0xFF0288D1),
      shadowColor: const Color(0xFF0288D1),
    ),
    FullIntentOption(
      key: 'Activity Partner',
      title: 'Activity Partner',
      description: 'Find trekking, fitness, board games & creative partners',
      iconBuilder: ({double size = 42}) => ActivityPartner3DIcon(size: size),
      bgGradient: const [Color(0xFFFFF2F6), Color(0xFFFFD8E5)],
      darkBgGradient: const [Color(0xFF331926), Color(0xFF221019)],
      accentColor: const Color(0xFFE91E63),
      shadowColor: const Color(0xFFE91E63),
    ),
    FullIntentOption(
      key: 'Dating',
      title: 'Dating',
      description: 'Explore romantic chemistry, casual dates & sparks',
      iconBuilder: ({double size = 42}) => Dating3DIcon(size: size),
      bgGradient: const [Color(0xFFF0FDF5), Color(0xFFD0F9E0)],
      darkBgGradient: const [Color(0xFF152C22), Color(0xFF0E1E17)],
      accentColor: const Color(0xFF00BFA5),
      shadowColor: const Color(0xFF00BFA5),
    ),
    FullIntentOption(
      key: 'Serious Relationship',
      title: 'Serious Relationship',
      description: 'Meaningful connection with intent toward long-term commitment',
      iconBuilder: ({double size = 42}) => SeriousRelationship3DIcon(size: size),
      bgGradient: const [Color(0xFFFFF9E8), Color(0xFFFFECC0)],
      darkBgGradient: const [Color(0xFF332916), Color(0xFF231B0E)],
      accentColor: const Color(0xFFFF8F00),
      shadowColor: const Color(0xFFFF8F00),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIntent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final sheetBg = isDark ? const Color(0xFF151022) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore by Intent',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Filter experiences by your primary meetup purpose',
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selected != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _selected = null);
                      widget.onSelectIntent(null);
                    },
                    child: Text(
                      'Clear',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Intent items list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              physics: const ClampingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = _selected == opt.key;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selected = isSelected ? null : opt.key;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark ? opt.darkBgGradient : opt.bgGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? opt.accentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.85)),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: opt.shadowColor.withValues(
                            alpha: isSelected ? 0.35 : 0.12,
                          ),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 3D Icon
                        opt.iconBuilder(size: 44),
                        const SizedBox(width: 14),

                        // Text details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : opt.accentColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.mutedText,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selected radio indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? opt.accentColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? opt.accentColor
                                  : (isDark ? Colors.white30 : AppColors.divider),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
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

          // Bottom CTA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onSelectIntent(_selected);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        _selected != null
                            ? 'Apply Filter (${_selected!})'
                            : 'View All Experiences',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
