import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';

/// Screen 7 (Image 6): Join Experience Flow
///
/// Features:
/// - Soft luxury watercolor ambient gradient background (cyan/amber/violet)
/// - Botanical leaves peeking from card edges
/// - Top bar with back arrow and title "Join Experience"
/// - Mini event summary card with photo, date, and venue
/// - "Your Intent" selection with stadium/pill chips
/// - Vibrant gradient selected state for active intent
/// - Full-width glowing gradient [ Confirm Join → ] button
/// - Subtle footer note "You can change your choice later"
class JoinExperienceSheet extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback onConfirmed;

  const JoinExperienceSheet({
    super.key,
    required this.experience,
    required this.onConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
    required VoidCallback onConfirmed,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JoinExperienceSheet(
        experience: experience,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<JoinExperienceSheet> createState() => _JoinExperienceSheetState();
}

class _JoinExperienceSheetState extends State<JoinExperienceSheet> {
  final Set<String> _selectedIntents = {'Dating'};
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final List<Map<String, dynamic>> _intentOptions = [
    {'name': 'Friendship', 'icon': Icons.people_alt_rounded},
    {'name': 'Activity Partner', 'icon': Icons.extension_rounded},
    {'name': 'Dating', 'icon': Icons.favorite_rounded},
    {'name': 'Serious Relationship', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Marriage Minded', 'icon': Icons.diamond_rounded},
    {'name': 'Just Exploring', 'icon': Icons.explore_rounded},
  ];

  void _handleConfirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    widget.onConfirmed();
    setState(() {
      _isSubmitting = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1435);
    final mutedTextColor = isDark ? AppColors.darkMutedText : const Color(0xFF7E7394);
    final cardBg = isDark ? const Color(0xFF1F1A2C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF332A45) : const Color(0xFFEDE9FE);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF140F21) : const Color(0xFFFAF7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            // Ambient Watercolor Gradient Glow (matches Image 6)
            Positioned(
              top: -40,
              left: -40,
              width: 220,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7DD3FC).withValues(alpha: isDark ? 0.15 : 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -30,
              width: 240,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFDE047).withValues(alpha: isDark ? 0.12 : 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 40,
              width: 280,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFDDD6FE).withValues(alpha: isDark ? 0.10 : 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Botanical foliage accents peeking from borders (Image 6)
            const Positioned(
              top: 10,
              left: -12,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.tropicalFoliage,
                width: 58,
                height: 100,
                rotation: 0.15,
                opacity: 0.88,
              ),
            ),
            const Positioned(
              top: 15,
              right: -10,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.tropicalFoliage,
                width: 50,
                height: 85,
                rotation: -0.25,
                opacity: 0.75,
              ),
            ),
            const Positioned(
              top: 250,
              right: -16,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.monstera,
                width: 60,
                height: 105,
                rotation: -0.20,
                opacity: 0.95,
              ),
            ),

            // Content
            if (_isSuccess)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _buildSuccessView(isDark, exp, primaryTextColor, mutedTextColor),
              )
            else
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top drag pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 2, bottom: 8),
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : const Color(0xFFDDD6FE),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Top Bar with back arrow & title (Image 6)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: primaryTextColor,
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              'Join Experience',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18.5,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // balance back button
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Mini summary card (Image 6)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor, width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: AppSmartImage(
                                        imagePath: exp.coverImageUrl,
                                        categoryHint: exp.categoryName,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exp.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: primaryTextColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 14,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                dateFormat.format(exp.startsAt),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: mutedTextColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                exp.venueName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: const Color(0xFF8B5CF6),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Section: Your Intent
                            Text(
                              'Your Intent',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select one or more (Primary first)',
                              style: AppTypography.bodySmall.copyWith(
                                color: mutedTextColor,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Intent Stadium Chips Grid (Image 6)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.85,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _intentOptions.length,
                              itemBuilder: (context, index) {
                                final opt = _intentOptions[index];
                                final name = opt['name'] as String;
                                final isSelected = _selectedIntents.contains(name);

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isSelected) {
                                        if (_selectedIntents.length > 1) {
                                          _selectedIntents.remove(name);
                                        }
                                      } else {
                                        _selectedIntents.add(name);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? AppColors.sunsetCtaGradient : null,
                                      color: isSelected ? null : cardBg,
                                      borderRadius: BorderRadius.circular(24),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: borderColor,
                                              width: 1.1,
                                            ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFF5A78).withValues(alpha: 0.38),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.025),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          opt['icon'] as IconData,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF8B5CF6),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected ? Colors.white : primaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 36),

                            // Confirm Join Button (Image 6)
                            GestureDetector(
                              onTap: _isSubmitting ? null : _handleConfirm,
                              child: Container(
                                height: 54,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: AppColors.sunsetCtaGradient,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5A78).withValues(alpha: 0.42),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Confirm Join',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                'You can change your choice later',
                                style: AppTypography.bodySmall.copyWith(
                                  color: mutedTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    bool isDark,
    ExperienceModel exp,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.purpleGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re In!',
              style: AppTypography.headlineMedium.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your RSVP for "${exp.title}" is confirmed. Enjoy the meetup!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
