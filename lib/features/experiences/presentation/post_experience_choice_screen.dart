import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/mutual_match_celebration_dialog.dart';
import '../../../shared/widgets/primary_button.dart';

class AttendeeChoice {
  final String name;
  final String avatarUrl;
  final String bio;
  String selectedOption; // 'friendship', 'activity_partner', 'dating', 'none'

  AttendeeChoice({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    this.selectedOption = 'none',
  });
}

/// Post-Experience Reconnect Screen (Screen 4 companion flow)
///
/// Enables participants to privately select who they enjoyed meeting
/// and in what context (Friendship, Activity Partner, Dating).
/// Fully adaptive with Light and Dark themes.
class PostExperienceChoiceScreen extends StatefulWidget {
  final ExperienceModel experience;

  const PostExperienceChoiceScreen({super.key, required this.experience});

  static Future<void> show(BuildContext context, ExperienceModel experience) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            PostExperienceChoiceScreen(experience: experience),
      ),
    );
  }

  @override
  State<PostExperienceChoiceScreen> createState() =>
      _PostExperienceChoiceScreenState();
}

class _PostExperienceChoiceScreenState
    extends State<PostExperienceChoiceScreen> {
  late List<AttendeeChoice> _attendees;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _attendees = [
      AttendeeChoice(
        name: 'Aditi Sen',
        avatarUrl: 'assets/images/aditi_avatar.png',
        bio:
            'Product designer & street photographer. Loves espresso and calm books.',
        selectedOption: 'friendship',
      ),
      AttendeeChoice(
        name: 'Vikram Mehta',
        avatarUrl: 'assets/images/vikram_avatar.png',
        bio: 'Architect, jazz enthusiast, and weekend runner.',
        selectedOption: 'activity_partner',
      ),
      AttendeeChoice(
        name: 'Priya Nair',
        avatarUrl: 'assets/images/priya_avatar.png',
        bio: 'Writer and botanist. Always hunting for vintage stationery.',
        selectedOption: 'dating',
      ),
    ];
  }

  void _handleSubmit() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Find any attendee with an active selection
    final selectedMatch = _attendees.firstWhere(
      (a) => a.selectedOption != 'none',
      orElse: () => _attendees.first,
    );

    if (selectedMatch.selectedOption != 'none') {
      final intentionLabel = selectedMatch.selectedOption == 'dating'
          ? 'Exploring Dating'
          : selectedMatch.selectedOption == 'friendship'
          ? 'Friendship'
          : 'Activity Partner';

      await MutualMatchCelebrationDialog.show(
        context,
        userName: 'You',
        userAvatarUrl: 'assets/images/sneha_avatar.png',
        matchName: selectedMatch.name,
        matchAvatarUrl: selectedMatch.avatarUrl,
        mutualIntention: intentionLabel,
        experienceTitle: widget.experience.title,
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
          ),
          title: Text(
            'Choices Recorded Privately',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your selections are kept 100% confidential. When there is a mutual match, a new connection and conversation thread will automatically appear in your Connections tab.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              height: 1.5,
            ),
          ),
          actions: [
            PrimaryButton(
              label: 'View Connections',
              height: 44,
              backgroundColor: isDark
                  ? AppColors.luminousMauve
                  : AppColors.deepPlum,
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/connections');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Post-Experience Reconnect',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glowing Checkmark Circle (Image 8 Screen 6)
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mintAccent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.mintAccent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintAccent.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.mintAccent,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You\'ve met some great people!',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Now choose who you\'d like to connect with. All choices are 100% mutual and private.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ..._attendees.map((attendee) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : AppColors.deepPlum.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: ClipOval(
                                    child: AppSmartImage(
                                      imagePath: attendee.avatarUrl,
                                      isAvatar: true,
                                      nameHint: attendee.name,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendee.name,
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: primaryTextColor,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        attendee.bio,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: mutedTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(height: 1, color: borderColor),
                            const SizedBox(height: 12),

                            Text(
                              'How would you like to stay in touch?',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.softCoral
                                    : AppColors.mauve,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildChoiceChip(
                                  attendee,
                                  'friendship',
                                  'Friendship',
                                  Icons.people_outline_rounded,
                                  isDark,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'activity_partner',
                                  'Activity Partner',
                                  Icons.sports_tennis_rounded,
                                  isDark,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'dating',
                                  'Explore Dating',
                                  Icons.favorite_rounded,
                                  isDark,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'none',
                                  'No Connection',
                                  Icons.close_rounded,
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? const Color(0xFF130F1E) : Colors.white)
                            .withValues(alpha: 0.72),
                        (isDark ? const Color(0xFF130F1E) : Colors.white)
                            .withValues(alpha: 0.95),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE5DEED).withValues(alpha: 0.60),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _isSubmitting ? null : _handleSubmit,
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
                                  color: const Color(
                                    0xFFFF5A78,
                                  ).withValues(alpha: 0.40),
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
                                    'Make My Choices',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    AttendeeChoice attendee,
    String value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = attendee.selectedOption == value;
    final activeBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final inactiveBg = isDark
        ? AppColors.darkElevated
        : AppColors.creamElevated;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => attendee.selectedOption = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.divider),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.luminousMauve : AppColors.mauve),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
