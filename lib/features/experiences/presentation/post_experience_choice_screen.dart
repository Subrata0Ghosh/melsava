import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
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
        name: 'Rhea Sen',
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        bio:
            'Product designer & street photographer. Loves espresso and calm books.',
        selectedOption: 'friendship',
      ),
      AttendeeChoice(
        name: 'Aarav Mehta',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        bio: 'Architect, jazz enthusiast, and weekend runner.',
        selectedOption: 'activity_partner',
      ),
      AttendeeChoice(
        name: 'Meera Nair',
        avatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
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
        userAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
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
              backgroundColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
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
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Who would you love to see again?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'From "${widget.experience.title}". All selections are 100% confidential. Mutual matches unlock contact without social pressure.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                    attendee.avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendee.name,
                                        style: AppTypography.titleMedium.copyWith(
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
                                color: isDark ? AppColors.softCoral : AppColors.mauve,
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                border: Border(top: BorderSide(color: borderColor, width: 0.9)),
              ),
              child: PrimaryButton(
                label: 'Save My Private Choices',
                isLoading: _isSubmitting,
                backgroundColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                onPressed: _handleSubmit,
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
    final inactiveBg = isDark ? AppColors.darkElevated : AppColors.creamElevated;

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
