import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/post_experience_repository.dart';

/// Screen 8 (from Image 3): Live Experience Screen
///
/// Immersive in-event interactive view:
/// - Header with dynamic, non-overflowing attendee avatar stack (+N)
/// - Themed event info bar with category badge and real-time active status
/// - Frosted glass card with dynamic event cover art preview
/// - "View Participants" button with interactive sheet
/// - Interactive floating reaction bar (❤️ 👏 😂 👍) with floating emoji physics
class LiveExperienceScreen extends ConsumerStatefulWidget {
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
  ConsumerState<LiveExperienceScreen> createState() =>
      _LiveExperienceScreenState();
}

class _LiveExperienceScreenState extends ConsumerState<LiveExperienceScreen>
    with TickerProviderStateMixin {
  final List<_FloatingEmoji> _activeEmojis = [];

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

  void _showParticipantsSheet(
    BuildContext context,
    ExperienceModel exp,
    List<MeetupCircleParticipant> attendees,
  ) {
    HapticFeedback.mediumImpact();
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id;
    final Set<String> wavedUserIds = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final totalCount = attendees.length;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1429),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                            '$totalCount participant${totalCount == 1 ? '' : 's'} in this session',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: Color(0xFF10B981),
                              size: 7,
                            ),
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
                  if (attendees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No participants in this session yet.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...attendees.map((attendee) {
                      final isMe =
                          (currentUserId != null &&
                              attendee.userId.isNotEmpty &&
                              attendee.userId == currentUserId) ||
                          (currentUser != null &&
                              (currentUser.displayName ?? '')
                                  .trim()
                                  .isNotEmpty &&
                              attendee.displayName.trim().toLowerCase() ==
                                  currentUser.displayName!
                                      .trim()
                                      .toLowerCase()) ||
                          attendee.displayName == 'You';

                      final attendeeKey = attendee.userId.isNotEmpty
                          ? attendee.userId
                          : attendee.displayName;
                      final isWaved = wavedUserIds.contains(attendeeKey);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                                  imagePath: attendee.avatarUrl,
                                  isAvatar: true,
                                  nameHint: attendee.displayName,
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
                                    isMe
                                        ? '${attendee.displayName} (You)'
                                        : attendee.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    attendee.role,
                                    style: TextStyle(
                                      color: attendee.role == 'Host'
                                          ? const Color(0xFFFBBF24)
                                          : Colors.white60,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'You',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setSheetState(() {
                                    wavedUserIds.add(attendeeKey);
                                  });
                                  _triggerReaction('👋');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sent a wave to ${attendee.displayName}! 👋',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF2E1A47),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isWaved
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.22)
                                        : const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isWaved
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.6)
                                          : const Color(
                                              0xFF8B5CF6,
                                            ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isWaved ? 'Waved! ' : 'Say Hi ',
                                        style: TextStyle(
                                          color: isWaved
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFDDD6FE),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        isWaved ? '✅' : '👋',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendeeStack(
    int totalCount,
    ExperienceModel exp,
    List<MeetupCircleParticipant> attendees,
  ) {
    const double avatarSize = 28;
    const double overlap = 18;

    final displayAttendees = attendees.take(3).toList();
    final remainingCount = totalCount - displayAttendees.length;
    final hasRemaining = remainingCount > 0;
    final totalItems =
        (displayAttendees.isNotEmpty ? displayAttendees.length : 1) +
        (hasRemaining ? 1 : 0);
    final totalWidth = totalItems > 1
        ? (((totalItems - 1) * overlap) + avatarSize)
        : avatarSize;

    return GestureDetector(
      onTap: () => _showParticipantsSheet(context, exp, attendees),
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
              if (displayAttendees.isNotEmpty)
                for (int i = 0; i < displayAttendees.length; i++)
                  Positioned(
                    left: (i * overlap).toDouble(),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF161C19),
                          width: 1.8,
                        ),
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
                          imagePath: displayAttendees[i].avatarUrl,
                          nameHint: displayAttendees[i].displayName,
                          isAvatar: true,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
              else
                Positioned(
                  left: 0,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF161C19),
                        width: 1.8,
                      ),
                    ),
                    child: ClipOval(
                      child: AppSmartImage(
                        imagePath: exp.hostAvatar,
                        nameHint: exp.hostName,
                        isAvatar: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (hasRemaining)
                Positioned(
                  left: (displayAttendees.length * overlap).toDouble(),
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
                      border: Border.all(
                        color: const Color(0xFF161C19),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.45),
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
    final currentUser = ref.watch(currentUserProvider);
    final participantsAsync = ref.watch(circleParticipantsProvider(exp.id));
    final liveParticipants = participantsAsync.valueOrNull;

    final List<MeetupCircleParticipant> attendees;
    if (liveParticipants != null && liveParticipants.isNotEmpty) {
      attendees = liveParticipants;
    } else {
      // Dynamic fallback based on exp and current user session
      final list = <MeetupCircleParticipant>[];
      if (exp.hostName.isNotEmpty) {
        list.add(
          MeetupCircleParticipant(
            userId: exp.hostId ?? '',
            displayName: exp.hostName,
            avatarUrl: exp.hostAvatar,
            bio: exp.hostBio ?? '',
            role: 'Host',
          ),
        );
      }
      if (currentUser != null &&
          currentUser.id != exp.hostId &&
          exp.isActiveMember) {
        list.add(
          MeetupCircleParticipant(
            userId: currentUser.id,
            displayName: currentUser.displayName ?? 'You',
            avatarUrl: currentUser.avatarUrl ?? '',
            bio: currentUser.bio ?? '',
            role: 'Attendee',
          ),
        );
      }
      attendees = list;
    }

    final totalParticipants = attendees.isNotEmpty
        ? attendees.length
        : (exp.currentParticipants > 0 ? exp.currentParticipants : 1);

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
              child: Container(color: Colors.black.withValues(alpha: 0.65)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                      _buildAttendeeStack(totalParticipants, exp, attendees),
                    ],
                  ),
                ),

                // ── Themed Event Info Pill Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                            exp.categoryIcon.isNotEmpty
                                ? exp.categoryIcon
                                : '✨',
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
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.45),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
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
                              onTap: () => _showParticipantsSheet(
                                context,
                                exp,
                                attendees,
                              ),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.sunsetCtaGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brightViolet.withValues(
                                        alpha: 0.4,
                                      ),
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
                final dy =
                    MediaQuery.of(context).size.height * 0.85 -
                    (progress * 380);
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
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
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
