import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';

/// Screen 7 (from Image 9): Join Experience Flow
///
/// Clean, transparent RSVP modal:
/// - Mini event preview card
/// - "Your Intent - Select one or more (Primary first)"
/// - Chips: Friendship, Activity Partner, Dating, Serious Relationship, Marriage Minded, Just Exploring
/// - Community Safety Guarantee
/// - Gradient [ Confirm Join → ] button
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
  bool _agreedToPledge = true;
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
    if (!_agreedToPledge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the community safety pledge to proceed.'),
        ),
      );
      return;
    }

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
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF130F1E) : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: _isSuccess
          ? _buildSuccessView(isDark, exp, primaryTextColor, mutedTextColor)
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    // Top drag pill
                    Container(
                      margin: const EdgeInsets.only(top: 14, bottom: 6),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title Header
                            Text(
                              'Join Experience',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: primaryTextColor,
                              ),
                            ),
                        const SizedBox(height: 16),

                        // Mini summary card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 0.9),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CachedNetworkImage(
                                    imageUrl: exp.coverImageUrl,
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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(exp.startsAt),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: mutedTextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      exp.venueName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: mutedTextColor,
                                        fontSize: 11.5,
                                      ),
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
                            fontSize: 15,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select one or more (Primary first)',
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Intent Grid Chips (Image 9 Screen 7)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
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
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.brightViolet.withValues(alpha: 0.2)
                                          : const Color(0xFFF3E8FF))
                                      : (isDark ? AppColors.darkElevated : AppColors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                                        : borderColor,
                                    width: isSelected ? 1.8 : 0.9,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      opt['icon'] as IconData,
                                      size: 18,
                                      color: isSelected
                                          ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                                          : mutedTextColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected
                                              ? (isDark ? Colors.white : AppColors.primaryPurple)
                                              : primaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 22),

                        // Community Safety Pledge
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 0.9),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _agreedToPledge,
                                activeColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                onChanged: (val) => setState(() => _agreedToPledge = val ?? true),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'I agree to respectful participation in vetted public venues.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: primaryTextColor,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Confirm Join Button
                        GestureDetector(
                          onTap: _isSubmitting ? null : _handleConfirm,
                          child: Container(
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppColors.sunsetCtaGradient,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5A78).withValues(alpha: 0.40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
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
                                : Text(
                                    'Confirm Join →',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'You can change your choice later',
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Botanical Monstera leaf peeking out from the right edge (Image 9 Screen 7)
            const Positioned(
              top: 175,
              right: -12,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.monstera,
                width: 55,
                height: 95,
                rotation: -0.22,
                opacity: 0.95,
              ),
            ),
          ],
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.purpleGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re In!',
              style: AppTypography.headlineMedium.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your RSVP for "${exp.title}" is confirmed. Enjoy the meetup!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
