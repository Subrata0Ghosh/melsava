import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';

/// Screen 8 (from Image 3): Live Experience Screen
///
/// Immersive in-event interactive view:
/// - Header with dynamic, non-overflowing attendee avatar stack (+N)
/// - Themed event info bar with category badge and real-time active status
/// - Frosted glass card with dynamic event cover art preview
/// - "View Participants" button with interactive sheet
/// - Interactive floating reaction bar (❤️ 👏 😂 👍) with floating emoji physics
class LiveExperienceScreen extends StatefulWidget {
  final ExperienceModel experience;

  const LiveExperienceScreen({super.key, required this.experience});

  static void show(BuildContext context, ExperienceModel experience) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => LiveExperienceScreen(experience: experience),
      ),
    );
  }

  @override
  State<LiveExperienceScreen> createState() => _LiveExperienceScreenState();
}

class _LiveExperienceScreenState extends State<LiveExperienceScreen>
    with TickerProviderStateMixin {
  final List<_FloatingEmoji> _activeEmojis = [];

  final List<String> _attendeeAvatars = [
    'assets/images/sneha_avatar.png',
    'assets/images/rohan_avatar.png',
    'assets/images/aditi_avatar.png',
    'assets/images/priya_avatar.png',
    'assets/images/vikram_avatar.png',
  ];

  void _triggerReaction(String emoji) {
    HapticFeedback.lightImpact();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final floatingEmoji = _FloatingEmoji(
      emoji: emoji,
      controller: controller,
      startX: 40.0 + (DateTime.now().millisecond % 240),
    );

    setState(() => _activeEmojis.add(floatingEmoji));

    controller.forward().then((_) {
      if (mounted) {
        setState(() => _activeEmojis.remove(floatingEmoji));
      }
      controller.dispose();
    });
  }

  void _showParticipantsSheet(BuildContext context, ExperienceModel exp) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final attendees = [
          {'name': exp.hostName, 'role': 'Host', 'avatar': exp.hostAvatar},
          {'name': 'Sneha Roy', 'role': 'Attendee', 'avatar': 'assets/images/sneha_avatar.png'},
          {'name': 'Rohan Sen', 'role': 'Attendee', 'avatar': 'assets/images/rohan_avatar.png'},
          {'name': 'Aditi Sharma', 'role': 'Attendee', 'avatar': 'assets/images/aditi_avatar.png'},
          {'name': 'Priya Patel', 'role': 'Attendee', 'avatar': 'assets/images/priya_avatar.png'},
          {'name': 'Vikram Joshi', 'role': 'Attendee', 'avatar': 'assets/images/vikram_avatar.png'},
        ];

        final totalCount = exp.currentParticipants > 0 ? exp.currentParticipants : 12;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1429),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meetup Circle',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$totalCount participants in this session',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                        SizedBox(width: 5),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...attendees.map((attendee) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: ClipOval(
                            child: AppSmartImage(
                              imagePath: attendee['avatar'],
                              isAvatar: true,
                              nameHint: attendee['name'],
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
                                attendee['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                attendee['role']!,
                                style: TextStyle(
                                  color: attendee['role'] == 'Host'
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white60,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'Say Hi 👋',
                            style: TextStyle(
                              color: Color(0xFFDDD6FE),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendeeStack(int totalCount, ExperienceModel exp) {
    const double avatarSize = 28;
    const double overlap = 18;
    final displayAvatars = _attendeeAvatars.take(3).toList();
    final remainingCount = (totalCount - displayAvatars.length).clamp(1, 99);
    final totalItems = displayAvatars.length + 1;
    final totalWidth = ((totalItems - 1) * overlap) + avatarSize;

    return GestureDetector(
      onTap: () => _showParticipantsSheet(context, exp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: SizedBox(
          width: totalWidth,
          height: avatarSize,
          child: Stack(
            children: [
              for (int i = 0; i < displayAvatars.length; i++)
                Positioned(
                  left: (i * overlap).toDouble(),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF161C19), width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AppSmartImage(
                        imagePath: displayAvatars[i],
                        isAvatar: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: (displayAvatars.length * overlap).toDouble(),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFF161C19), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final e in _activeEmojis) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experience;
    final totalParticipants = exp.currentParticipants > 0 ? exp.currentParticipants : 12;

    return Scaffold(
      backgroundColor: const Color(0xFF161C19),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Atmospheric Background with Subtle Photo & Blur ───────────
          Positioned.fill(
            child: AppSmartImage(
              imagePath: exp.coverImageUrl.isNotEmpty
                  ? exp.coverImageUrl
                  : 'assets/images/live_meetup_cafe_bg.png',
              categoryHint: exp.categoryName,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // ── Ambient Glow Vignette ──────────────────────────────────────
          Positioned(
            top: 100,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF67B99A).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content Layout ────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar & Attendee Stack ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Live Experience',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAttendeeStack(totalParticipants, exp),
                    ],
                  ),
                ),

                // ── Themed Event Info Pill Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            exp.categoryIcon.isNotEmpty ? exp.categoryIcon : '✨',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Text(
                                    'Small group circle',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$totalParticipants attending',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Center Frosted Glass Card (Screen 8) ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Circular experience cover preview
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: AppSmartImage(
                                  imagePath: exp.coverImageUrl,
                                  categoryHint: exp.categoryName,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Heading
                            Text(
                              'Enjoy the moment,\nmake new friends!',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You are live in the group circle for ${exp.title}. Send reactions and say hello!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // "View Participants" Gradient Button
                            GestureDetector(
                              onTap: () => _showParticipantsSheet(context, exp),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  gradient: AppColors.sunsetCtaGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brightViolet.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'View Participants ($totalParticipants)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Bottom Floating Reaction Bar (Screen 8) ─────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildReactionButton('❤️', () => _triggerReaction('❤️')),
                      const SizedBox(width: 16),
                      _buildReactionButton('👏', () => _triggerReaction('👏')),
                      const SizedBox(width: 16),
                      _buildReactionButton('😂', () => _triggerReaction('😂')),
                      const SizedBox(width: 16),
                      _buildReactionButton('👍', () => _triggerReaction('👍')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Animated Floating Reactions ────────────────────────────────
          for (final emojiItem in _activeEmojis)
            AnimatedBuilder(
              animation: emojiItem.controller,
              builder: (context, child) {
                final progress = emojiItem.controller.value;
                final dy = MediaQuery.of(context).size.height * 0.85 - (progress * 380);
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final scale = 0.8 + (progress * 0.6);

                return Positioned(
                  left: emojiItem.startX,
                  top: dy,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        emojiItem.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _FloatingEmoji {
  final String emoji;
  final AnimationController controller;
  final double startX;

  _FloatingEmoji({
    required this.emoji,
    required this.controller,
    required this.startX,
  });
}
