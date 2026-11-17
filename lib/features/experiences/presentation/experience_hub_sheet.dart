import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/primary_button.dart';
import 'live_experience_screen.dart';

/// Experience Hub (Pre-Meetup Group Space)
///
/// Inspired by MeetEm (group chat / room) and Unveil/Friendzyme (coordination & icebreakers).
/// For joined participants prior to the event, providing:
/// - Signature botanical foliage accents & ambient glowing watercolor meshes
/// - Event countdown & status with venue spot map navigation
/// - Interactive participant micro-group list (3–5 people) with profile cards
/// - Quick action pills (Calendar, Safety, Venue Guide)
/// - Conversation starter icebreakers with copy & shuffle
/// - Confidential post-event reconnect guarantee
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
    'If you could master any skill overnight, what would you choose?',
    'What is your go-to comfort coffee or food spot around here?',
  ];

  int _selectedPromptIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF130F1E) : AppColors.white;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor =
        isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    // Calculate countdown label
    final now = DateTime.now();
    final difference = exp.startsAt.difference(now);
    final String countdownLabel = difference.inDays > 0
        ? 'In ${difference.inDays} ${difference.inDays == 1 ? "day" : "days"}'
        : (difference.inHours > 0
            ? 'In ${difference.inHours} hrs'
            : 'Starting Soon');

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Ambient Watercolor Glow Orbs (MELSAVA Signature) ──
          Positioned(
            top: -40,
            right: -30,
            width: 250,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFEF3C7)
                        .withValues(alpha: isDark ? 0.08 : 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -40,
            width: 260,
            height: 260,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDDD6FE)
                        .withValues(alpha: isDark ? 0.10 : 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            right: -30,
            width: 240,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD1FAE5)
                        .withValues(alpha: isDark ? 0.08 : 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Botanical Foliage Accents Peeking From Borders ──
          const Positioned(
            top: 12,
            right: -10,
            child: BotanicalLeafDecoration(
              style: BotanicalLeafStyle.tropicalFoliage,
              width: 56,
              height: 95,
              rotation: -0.25,
              opacity: 0.88,
            ),
          ),
          const Positioned(
            top: 8,
            left: -12,
            child: BotanicalLeafDecoration(
              style: BotanicalLeafStyle.eucalyptus,
              width: 48,
              height: 85,
              rotation: 0.18,
              opacity: 0.78,
            ),
          ),
          const Positioned(
            top: 260,
            left: -16,
            child: BotanicalLeafDecoration(
              style: BotanicalLeafStyle.monstera,
              width: 62,
              height: 108,
              rotation: 0.22,
              opacity: 0.95,
            ),
          ),
          const Positioned(
            bottom: 120,
            right: -14,
            child: BotanicalLeafDecoration(
              style: BotanicalLeafStyle.wildGrass,
              width: 50,
              height: 96,
              rotation: -0.18,
              opacity: 0.82,
            ),
          ),

          // ── Main Content Column ──
          Column(
            children: [
              // Top Drag Handle
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
                      // ── Hub Header with Icon & Close Button ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.hub_rounded,
                              size: 22,
                              color: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.mauve,
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
                          // Close (✕) Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : AppColors.divider,
                                  width: 0.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.deepPlum,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ── Event Confirmation Banner with Countdown & Spot Map ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF281E38),
                                    const Color(0xFF191325)
                                  ]
                                : [
                                    AppColors.creamElevated,
                                    AppColors.warmIvory
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.divider,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintAccent
                                        .withValues(alpha: 0.2),
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppColors.softCoral
                                            : AppColors.vividCoral)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 11,
                                        color: isDark
                                            ? AppColors.softCoral
                                            : AppColors.vividCoral,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        countdownLabel,
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.softCoral
                                              : AppColors.vividCoral,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    dateFormat.format(exp.startsAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.softCoral
                                          : AppColors.mauve,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              exp.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve,
                                ),
                                const SizedBox(width: 5),
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
                                const SizedBox(width: 8),
                                // "Map Spot" action pill
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showVenueMapDialog(
                                        context, exp, isDark, primaryTextColor);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? AppColors.brightViolet
                                              : AppColors.primaryPurple)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (isDark
                                                ? AppColors.brightViolet
                                                : AppColors.primaryPurple)
                                            .withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🗺️',
                                            style: TextStyle(fontSize: 11)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Spot Map',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: isDark
                                                ? AppColors.brightViolet
                                                : AppColors.primaryPurple,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Quick Action Pills Row ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildQuickActionChip(
                              icon: Icons.calendar_month_rounded,
                              label: 'Add to Calendar',
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Event added to calendar: ${exp.title}'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickActionChip(
                              icon: Icons.shield_rounded,
                              label: 'Verified Public Spot',
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showSafetyDialog(context, isDark);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickActionChip(
                              icon: Icons.share_rounded,
                              label: 'Share Meetup',
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Meetup invitation link copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Micro-Group Participants Roster ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MICRO-GROUP PARTICIPANTS (${exp.currentParticipants}/${exp.maxParticipants})',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color:
                                  isDark ? AppColors.softCoral : AppColors.mauve,
                            ),
                          ),
                          Text(
                            'Tap to view info',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10.5,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.30 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Host row
                            _buildParticipantRow(
                              name: exp.hostName,
                              avatarUrl: exp.hostAvatar,
                              tag: 'Curated Host',
                              tagColor: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.mauve,
                              bio:
                                  'Certified community organizer & local nature trail enthusiast.',
                              isHost: true,
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              mutedTextColor: mutedTextColor,
                            ),
                            Divider(height: 20, color: borderColor),

                            // Attendee rows
                            for (int i = 0;
                                i < exp.attendeeAvatars.length;
                                i++) ...[
                              _buildParticipantRow(
                                name: i == 0
                                    ? 'Rhea Sen'
                                    : (i == 1
                                        ? 'Aarav Mehta'
                                        : 'You (Confirmed)'),
                                avatarUrl: exp.attendeeAvatars[i],
                                tag: i == 2 ? 'You' : 'Attendee',
                                tagColor: i == 2
                                    ? AppColors.mintAccent
                                    : AppColors.softCoral,
                                bio: i == 0
                                    ? 'Graphic designer who loves weekend treks, filter coffee, and acoustic guitar.'
                                    : (i == 1
                                        ? 'Software engineer & amateur landscape photographer.'
                                        : 'You! Attending in-person with confirmed reservation.'),
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

                      // ── Guided Icebreaker Prompts ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GUIDED ICEBREAKERS',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color:
                                  isDark ? AppColors.softCoral : AppColors.mauve,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedPromptIndex = (_selectedPromptIndex +
                                        1) %
                                    _icebreakerPrompts.length;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎲',
                                    style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  'Shuffle Next',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve)
                                      .withValues(alpha: isDark ? 0.20 : 0.10)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple)
                                    : borderColor,
                                width: isSelected ? 1.6 : 0.8,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark
                                                ? AppColors.brightViolet
                                                : AppColors.primaryPurple)
                                            .withValues(alpha: 0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 19,
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple)
                                      : mutedTextColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _icebreakerPrompts[index],
                                    style: AppTypography.bodySmall.copyWith(
                                      color: primaryTextColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Clipboard.setData(ClipboardData(
                                          text: _icebreakerPrompts[index]));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Icebreaker copied to clipboard!'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // ── Post-Event Reconnect Confidentiality Guarantee ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.sage)
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
                              color: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.mauve,
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

                      // ── Enter Live Experience Mode ──
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
                        backgroundColor: isDark
                            ? AppColors.luminousMauve
                            : AppColors.deepPlum,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.divider,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.deepPlum,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow({
    required String name,
    required String avatarUrl,
    required String tag,
    required Color tagColor,
    required String bio,
    required bool isHost,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _showParticipantProfileSheet(
          name: name,
          avatarUrl: avatarUrl,
          tag: tag,
          tagColor: tagColor,
          bio: bio,
          isHost: isHost,
          isDark: isDark,
          primaryTextColor: primaryTextColor,
          mutedTextColor: mutedTextColor,
        );
      },
      child: Row(
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
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleSmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                  ],
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
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: mutedTextColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  void _showParticipantProfileSheet({
    required String name,
    required String avatarUrl,
    required String tag,
    required Color tagColor,
    required String bio,
    required bool isHost,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B142A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tagColor, width: 2.5),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: AppSmartImage(
                  imagePath: avatarUrl,
                  isAvatar: true,
                  nameHint: name,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tag,
                style: AppTypography.labelSmall.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Say Hello 👋',
              gradient: AppColors.sunsetCtaGradient,
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Waved hello to $name!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVenueMapDialog(
    BuildContext context,
    ExperienceModel exp,
    bool isDark,
    Color primaryTextColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1730) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exp.venueName,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exp.venueAddress,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.mutedText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vetted Public Venue • Safety Checked',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.brightViolet : AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(
                  text: '${exp.venueName}, ${exp.venueAddress}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Venue address copied to clipboard!'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy Address'),
          ),
        ],
      ),
    );
  }

  void _showSafetyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1730) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            Text(
              'Safety & Guidelines',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• All MELSAVA meetups take place strictly in verified public venues.\n\n'
              '• Curated hosts guide conversations and ensure everyone feels welcome and respected.\n\n'
              '• Confidential Reconnect ensures no awkwardness: contact info is shared only upon mutual match.\n\n'
              '• Emergency assistance and moderation are available 24/7.',
              style: TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
