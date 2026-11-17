import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/primary_button.dart';
import 'live_experience_screen.dart';

/// Experience Hub (Pre-Meetup Group Space)
///
/// Inspired by MeetEm (group chat / room) and Unveil/Friendzyme (coordination & icebreakers).
/// For joined participants prior to the event, providing:
/// - Event countdown & status
/// - Participant micro-group list (3–5 people)
/// - Conversation starter icebreakers
/// - Public venue meeting point details
class ExperienceHubSheet extends StatefulWidget {
  final ExperienceModel experience;

  const ExperienceHubSheet({super.key, required this.experience});

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExperienceHubSheet(experience: experience),
    );
  }

  @override
  State<ExperienceHubSheet> createState() => _ExperienceHubSheetState();
}

class _ExperienceHubSheetState extends State<ExperienceHubSheet> {
  final List<String> _icebreakerPrompts = [
    'What is a favorite book or creative project you enjoyed recently?',
    'What is something you have always wanted to try in the city?',
    'What makes a weekend genuinely relaxing for you?',
  ];

  int _selectedPromptIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF130F1E) : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hub Header
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
                          Icons.hub_rounded,
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
                              'Experience Hub',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              'Pre-meetup space for confirmed participants',
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

                  // Event Confirmation Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF281E38), const Color(0xFF191325)]
                            : [AppColors.creamElevated, AppColors.warmIvory],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.mintAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CONFIRMED RSVP',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.mintAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateFormat.format(exp.startsAt),
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.softCoral : AppColors.mauve,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exp.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${exp.venueName} · ${exp.venueAddress}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: mutedTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Micro-Group Participants Roster (Unveil / MeetEm inspired)
                  Text(
                    'MICRO-GROUP PARTICIPANTS (${exp.currentParticipants}/${exp.maxParticipants})',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: isDark ? AppColors.softCoral : AppColors.mauve,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 0.9),
                    ),
                    child: Column(
                      children: [
                        // Host row
                        _buildParticipantRow(
                          name: exp.hostName,
                          avatarUrl: exp.hostAvatar,
                          tag: 'Curated Host',
                          tagColor: isDark ? AppColors.luminousMauve : AppColors.mauve,
                          isHost: true,
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          mutedTextColor: mutedTextColor,
                        ),
                        Divider(height: 20, color: borderColor),

                        // Attendee rows
                        for (int i = 0; i < exp.attendeeAvatars.length; i++) ...[
                          _buildParticipantRow(
                            name: i == 0 ? 'Rhea Sen' : (i == 1 ? 'Aarav Mehta' : 'You (Confirmed)'),
                            avatarUrl: exp.attendeeAvatars[i],
                            tag: i == 2 ? 'You' : 'Attendee',
                            tagColor: i == 2 ? AppColors.mintAccent : AppColors.softCoral,
                            isHost: false,
                            isDark: isDark,
                            primaryTextColor: primaryTextColor,
                            mutedTextColor: mutedTextColor,
                          ),
                          if (i < exp.attendeeAvatars.length - 1)
                            Divider(height: 18, color: borderColor),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Guided Icebreaker Prompts (idea.txt Section I)
                  Text(
                    'GUIDED ICEBREAKERS',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: isDark ? AppColors.softCoral : AppColors.mauve,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Light conversational prompts to help kickstart genuine conversation at the table.',
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...List.generate(_icebreakerPrompts.length, (index) {
                    final isSelected = _selectedPromptIndex == index;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPromptIndex = index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.luminousMauve.withValues(alpha: 0.15)
                                  : AppColors.mauve.withValues(alpha: 0.08))
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                                : borderColor,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: isSelected
                                  ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                                  : mutedTextColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _icebreakerPrompts[index],
                                style: AppTypography.bodySmall.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Post-Event Reconnect Reminder
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : AppColors.sage)
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'After attending, you will receive your private Reconnect screen to select who you\'d like to stay in touch with. Selections remain 100% confidential.',
                            style: AppTypography.bodySmall.copyWith(
                              color: primaryTextColor,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enter Live Experience Mode (Image 3 Screen 8)
                  PrimaryButton(
                    label: 'Enter Live Experience Mode →',
                    gradient: AppColors.sunsetCtaGradient,
                    onPressed: () {
                      Navigator.of(context).pop();
                      LiveExperienceScreen.show(context, exp);
                    },
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: 'Done',
                    backgroundColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow({
    required String name,
    required String avatarUrl,
    required String tag,
    required Color tagColor,
    required bool isHost,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tagColor, width: 1.8),
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: AppSmartImage(
              imagePath: avatarUrl,
              isAvatar: true,
              nameHint: name,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.titleSmall.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Text(
                isHost ? 'Community Host' : 'Attending in-person',
                style: AppTypography.bodySmall.copyWith(
                  color: mutedTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: AppTypography.labelSmall.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
