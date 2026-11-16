import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/primary_button.dart';

/// Screen 3: Join Experience Flow
///
/// Inspired by Dribbble Social Meetup Event Planner (shots/27290057),
/// providing a guided, transparent RSVP experience:
/// 1. Experience & Venue Confirmation summary
/// 2. Meetup Intention / Vibe preference ("Great conversation", "Creative ideas", "Activity companion", "Exploring dating")
/// 3. Community Safety & Respect Pledge
/// 4. Tactile Confirmation with Confetti/Tick micro-animation
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
  int _selectedVibeIndex = 0;
  bool _agreedToPledge = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final List<Map<String, dynamic>> _vibeOptions = [
    {
      'title': 'Great Conversations',
      'subtitle': 'Engaging stories, intellectual thoughts & relaxed banter',
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'title': 'Activity & Shared Passions',
      'subtitle': 'Enjoying the event focus and discovering shared hobbies',
      'icon': Icons.interests_outlined,
    },
    {
      'title': 'Open to New Friendships',
      'subtitle': 'Expanding my personal circle with like-minded locals',
      'icon': Icons.people_outline_rounded,
    },
    {
      'title': 'Exploring Dating Chemistry',
      'subtitle': 'Open to meeting a romantic match organically through activities',
      'icon': Icons.favorite_border_rounded,
    },
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

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    widget.onConfirmed();
    setState(() {
      _isSubmitting = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF14101F) : AppColors.white;
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
          : Column(
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
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.luminousMauve : AppColors.mauve)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                size: 22,
                                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Micro-Group Meetup',
                                    style: AppTypography.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 19,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    'Capped at ${exp.maxParticipants} participants · Vetted public venue',
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

                        const SizedBox(height: 18),

                        // Mini summary card
                        Container(
                          padding: const EdgeInsets.all(14),
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
                                  width: 60,
                                  height: 60,
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
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 13,
                                          color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            dateFormat.format(exp.startsAt),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: mutedTextColor,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.place_rounded,
                                          size: 13,
                                          color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            exp.venueName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: mutedTextColor,
                                              fontSize: 11.5,
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

                        // Section 1: Meetup Intention / Vibe
                        Text(
                          'WHAT IS YOUR INTENTION FOR THIS MEETUP?',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isDark ? AppColors.softCoral : AppColors.mauve,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This guides your post-event mutual matching compatibility.',
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Vibe options list
                        ...List.generate(_vibeOptions.length, (index) {
                          final vibe = _vibeOptions[index];
                          final isSelected = _selectedVibeIndex == index;
                          final activeColor = isDark ? AppColors.luminousMauve : AppColors.deepPlum;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedVibeIndex = index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.luminousMauve.withValues(alpha: 0.16)
                                        : AppColors.mauve.withValues(alpha: 0.08))
                                    : (isDark ? AppColors.darkSurface : AppColors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : (isDark ? AppColors.darkBorder : AppColors.divider),
                                  width: isSelected ? 1.6 : 0.9,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? activeColor
                                          : (isDark
                                              ? AppColors.darkElevated
                                              : AppColors.warmIvory),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      vibe['icon'] as IconData,
                                      size: 18,
                                      color: isSelected ? Colors.white : mutedTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vibe['title'] as String,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: primaryTextColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          vibe['subtitle'] as String,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: mutedTextColor,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 20,
                                      color: activeColor,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 18),

                        // Section 2: Safety & Respect Pledge
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkSurface : AppColors.sage)
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.divider,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 18,
                                    color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MELSAVA Community Safe Pledge',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Public vetted venue only — never in private residences.\n'
                                '• No contact information shared beforehand.\n'
                                '• Reconnections after the meetup are 100% mutual and private.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: primaryTextColor,
                                  fontSize: 11.5,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(() => _agreedToPledge = !_agreedToPledge),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _agreedToPledge,
                                        activeColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        onChanged: (val) =>
                                            setState(() => _agreedToPledge = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'I agree to be respectful and adhere to safety standards.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: primaryTextColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Action Bar
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: sheetBg,
                      border: Border(top: BorderSide(color: borderColor, width: 0.9)),
                    ),
                    child: PrimaryButton(
                      label: exp.hasJoined ? 'Confirm Cancel RSVP' : 'Confirm RSVP & Join Group',
                      isLoading: _isSubmitting,
                      backgroundColor: exp.hasJoined
                          ? AppColors.error
                          : (isDark ? AppColors.luminousMauve : AppColors.deepPlum),
                      onPressed: _handleConfirm,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Success view with celebration
  Widget _buildSuccessView(
    bool isDark,
    ExperienceModel exp,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppColors.luminousMauve : AppColors.mauve,
                    AppColors.mintAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mintAccent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              exp.hasJoined ? 'RSVP Updated' : 'You\'re on the Guestlist! 🎉',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exp.hasJoined
                  ? 'Your reservation has been cancelled.'
                  : 'You\'ve secured your spot for ${exp.title}. We look forward to seeing you at ${exp.venueName}!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
