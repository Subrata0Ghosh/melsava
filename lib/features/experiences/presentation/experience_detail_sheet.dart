import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/experience_share_sheet.dart';
import '../../../shared/widgets/trending_badge.dart';
import '../data/experiences_repository.dart';
import '../data/followed_hosts_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import 'experience_hub_sheet.dart';
import 'join_experience_sheet.dart';

/// Full-Screen Experience Detail Screen (Screen 6 from master design)
/// Features:
/// - True full-screen page route with zero top margin / drag handle
/// - Full-bleed hero image header reaching under the status bar
/// - Floating glassmorphic action buttons (Back, Bookmark, Share)
/// - Organic asymmetrical wave transition matching Image 3
/// - Sculptural 3D rim highlight along the wave
/// - Live metadata chips (Date & Time, Duration, Venue/Online, Live Joined count)
/// - Host card with verified badge and host bio
/// - Vetted Public Venue preview or Online Experience indicator
/// - Real cancellation policy display
/// - Safe Public Meeting Guarantee
/// - Corner botanical foliage peeking from perimeter
/// - Sticky full-width gradient [ Join / Waitlist / Cancel RSVP ] CTA button
class ExperienceDetailSheet extends ConsumerStatefulWidget {
  final ExperienceModel experience;
  final VoidCallback? onToggleJoin;

  const ExperienceDetailSheet({
    super.key,
    required this.experience,
    this.onToggleJoin,
  });

  /// Navigates to the full-screen Experience Detail Screen
  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
    VoidCallback? onToggleJoin,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExperienceDetailSheet(
              experience: experience,
              onToggleJoin: onToggleJoin,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<ExperienceDetailSheet> createState() =>
      _ExperienceDetailSheetState();
}

class _ExperienceDetailSheetState extends ConsumerState<ExperienceDetailSheet> {
  bool _isBookmarked = false;
  bool _isCancelling = false;

  Future<void> _openJoinFlow(ExperienceModel exp) async {
    final result = await JoinExperienceSheet.show(
      context,
      experience: exp,
      onConfirmJoin: () =>
          ref.read(experienceActionControllerProvider).joinExperience(exp.id),
    );
    if (result != null && mounted) {
      widget.onToggleJoin?.call();
    }
  }

  Future<void> _confirmCancel(ExperienceModel exp) async {
    if (_isCancelling) return;
    final isWaitlist = exp.isWaitlisted;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: isWaitlist ? 'Leave Waitlist?' : 'Cancel Your RSVP?',
      message: isWaitlist
          ? 'You will give up your spot on the waitlist for "${exp.title}".'
          : 'Are you sure you want to cancel your attendance? If there is a waitlist, the next person will automatically be invited.',
      confirmLabel: isWaitlist ? 'Leave' : 'Cancel RSVP',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        await ref
            .read(experienceActionControllerProvider)
            .cancelMembership(exp.id);
        if (mounted) {
          widget.onToggleJoin?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isWaitlist
                    ? 'You have left the waitlist.'
                    : 'Your RSVP was cancelled successfully.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg.isNotEmpty
                    ? msg
                    : 'We couldn\'t cancel your reservation. Please try again.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCancelling = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch live experience provider for fresh capacity and membership state
    final liveAsync = ref.watch(experienceDetailProvider(widget.experience.id));
    final exp = liveAsync.valueOrNull ?? widget.experience;

    final currentUser = ref.watch(currentUserProvider);
    final followedHosts = ref.watch(followedHostsProvider);
    final isHost = currentUser != null &&
        exp.hostId != null &&
        currentUser.id == exp.hostId;
    final hostKey = (exp.hostId != null && exp.hostId!.isNotEmpty)
        ? exp.hostId!
        : exp.hostName;
    final isFollowing = followedHosts.contains(hostKey) ||
        followedHosts.contains(exp.hostName);

    final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');

    final sheetBg = isDark ? const Color(0xFF130F1E) : Colors.white;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.42;
    const waveOverlap = 42.0;

    return Scaffold(
      backgroundColor: sheetBg,
      body: Stack(
        children: [
          // ── Scrollable Body ──
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Full-Bleed Hero Image with Gradient & Overlays ──
                SizedBox(
                  height: heroHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image (Edge to edge reaching under status bar)
                      AppSmartImage(
                        imagePath: exp.coverImageUrl,
                        categoryHint: '${exp.title} ${exp.categoryName}',
                        fit: BoxFit.cover,
                      ),

                      // Gradient Shading for floating status bar & buttons
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Trending badge & spots remaining on bottom-left of hero image
                      Positioned(
                        left: 18,
                        bottom: waveOverlap + 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TrendingBadge(
                              fontSize: 12,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildCapacityHeroPill(exp, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Sculpted Organic Curved Content Section ──
                Transform.translate(
                  offset: const Offset(0, -waveOverlap),
                  child: CustomPaint(
                    painter: _OrganicWaveBorderPainter(
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                    child: ClipPath(
                      clipper: const _OrganicWaveClipper(),
                      child: Container(
                        color: sheetBg,
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Botanical leaves decorating the right margin
                            const Positioned(
                              top: 60,
                              right: -24,
                              child: BotanicalLeafDecoration(
                                style: BotanicalLeafStyle.monstera,
                                width: 70,
                                height: 115,
                                rotation: -0.22,
                                opacity: 0.20,
                              ),
                            ),

                            // Content Details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Description
                                Text(
                                  exp.title,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 23,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  exp.description.isNotEmpty
                                      ? exp.description
                                      : 'Explore nature, meet new people and create unforgettable memories.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: mutedTextColor,
                                    fontSize: 13.5,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Inline Meta Info Chips Row ──
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoChip(
                                      Icons.calendar_today_rounded,
                                      dateFormat.format(exp.startsAt),
                                      isDark,
                                      mutedTextColor,
                                      primaryTextColor,
                                    ),
                                    if (exp.durationMinutes > 0)
                                      _buildInfoChip(
                                        Icons.schedule_rounded,
                                        _formatDuration(exp.durationMinutes),
                                        isDark,
                                        mutedTextColor,
                                        primaryTextColor,
                                      ),
                                    _buildInfoChip(
                                      exp.isOnline
                                          ? Icons.videocam_rounded
                                          : Icons.location_on_rounded,
                                      exp.isOnline
                                          ? 'Online Experience'
                                          : (exp.venueName.isNotEmpty
                                                ? exp.venueName
                                                : (exp.city.isNotEmpty
                                                      ? exp.city
                                                      : 'Public Venue')),
                                      isDark,
                                      mutedTextColor,
                                      primaryTextColor,
                                    ),
                                    _buildInfoChip(
                                      Icons.groups_rounded,
                                      exp.hasUnlimitedCapacity
                                          ? '${exp.currentParticipants} Joined'
                                          : '${exp.currentParticipants}/${exp.maxParticipants} Joined',
                                      isDark,
                                      mutedTextColor,
                                      primaryTextColor,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // ── About Section ──
                                Text(
                                  'About this Experience',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exp.description.isNotEmpty
                                      ? exp.description
                                      : 'A refreshing social experience with like-minded people. Perfect for real connections! Enjoy meaningful face-to-face moments and genuine conversations without awkward small talk.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: mutedTextColor,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Category Tags
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildTagChip(
                                      '${exp.categoryIcon.isNotEmpty ? '${exp.categoryIcon} ' : ''}${exp.categoryName}',
                                      isDark,
                                    ),
                                    if (exp.isOnline)
                                      _buildTagChip('Live Online', isDark),
                                    if (!exp.isOnline && exp.city.isNotEmpty)
                                      _buildTagChip(exp.city, isDark),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // ── Venue / Location Card ──
                                Text(
                                  exp.isOnline
                                      ? 'LIVE ONLINE EXPERIENCE'
                                      : 'VETTED PUBLIC VENUE',
                                  style: AppTypography.labelSmall.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.softCoral
                                        : AppColors.mauve,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color:
                                              (isDark
                                                      ? AppColors.luminousMauve
                                                      : AppColors.mauve)
                                                  .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          exp.isOnline
                                              ? Icons.videocam_rounded
                                              : Icons.place_rounded,
                                          color: isDark
                                              ? AppColors.luminousMauve
                                              : AppColors.mauve,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exp.isOnline
                                                  ? 'Interactive Online Session'
                                                  : (exp.venueName.isNotEmpty
                                                        ? exp.venueName
                                                        : (exp.city.isNotEmpty
                                                              ? exp.city
                                                              : 'Vetted Public Spot')),
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                    color: primaryTextColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14.5,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              exp.isOnline
                                                  ? 'Meeting link and details will become available to confirmed members before the session.'
                                                  : (exp.venueAddress.isNotEmpty
                                                        ? exp.venueAddress
                                                        : (exp.city.isNotEmpty
                                                              ? 'Public meeting venue in ${exp.city}'
                                                              : 'Public verified venue')),
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: mutedTextColor,
                                                    fontSize: 12.5,
                                                    height: 1.4,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Host Bio Card ──
                                Text(
                                  'HOSTED BY',
                                  style: AppTypography.labelSmall.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.softCoral
                                        : AppColors.mauve,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.brightViolet
                                                : AppColors.primaryPurple,
                                            width: 1.8,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: AppSmartImage(
                                            imagePath: exp.hostAvatar,
                                            isAvatar: true,
                                            nameHint: exp.hostName,
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
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    exp.hostName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTypography
                                                        .titleSmall
                                                        .copyWith(
                                                          color:
                                                              primaryTextColor,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 14.5,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 16,
                                                  color: isDark
                                                      ? AppColors.brightViolet
                                                      : AppColors.primaryPurple,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              (exp.hostBio != null &&
                                                      exp.hostBio!.isNotEmpty)
                                                  ? exp.hostBio!
                                                  : 'Community Experience Host',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: mutedTextColor,
                                                    fontSize: 11.5,
                                                    height: 1.35,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Follow / Host Badge
                                      if (isHost)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 13,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isDark
                                                    ? AppColors.softCoral
                                                    : AppColors.deepPlum)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: (isDark
                                                      ? AppColors.softCoral
                                                      : AppColors.deepPlum)
                                                  .withValues(alpha: 0.35),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified_user_rounded,
                                                size: 14,
                                                color: isDark
                                                    ? AppColors.softCoral
                                                    : AppColors.deepPlum,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'You (Host)',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppColors.softCoral
                                                      : AppColors.deepPlum,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (isFollowing)
                                        GestureDetector(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            await ref
                                                .read(followedHostsProvider
                                                    .notifier)
                                                .toggleFollow(hostKey);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Unfollowed ${exp.hostName}.',
                                                ),
                                                duration:
                                                    const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (isDark
                                                      ? AppColors.darkElevated
                                                      : Colors.white)
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.brightViolet
                                                    : AppColors.primaryPurple,
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: isDark
                                                      ? AppColors.brightViolet
                                                      : AppColors.primaryPurple,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Following',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors.brightViolet
                                                        : AppColors.primaryPurple,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: () async {
                                            HapticFeedback.mediumImpact();
                                            await ref
                                                .read(followedHostsProvider
                                                    .notifier)
                                                .toggleFollow(hostKey);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'You are now following ${exp.hostName}. You\'ll see their new curated experiences prioritized.',
                                                ),
                                                duration:
                                                    const Duration(seconds: 3),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 7.5,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppColors.purpleGradient,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryPurple
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.add_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Follow',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Cancellation Policy Card ──
                                Text(
                                  'CANCELLATION POLICY',
                                  style: AppTypography.labelSmall.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.softCoral
                                        : AppColors.mauve,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.event_repeat_rounded,
                                        size: 20,
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          (exp.cancellationPolicy != null &&
                                                  exp
                                                      .cancellationPolicy!
                                                      .isNotEmpty)
                                              ? exp.cancellationPolicy!
                                              : 'Free cancellation up to 24 hours before the experience starts. If you cancel, your place is offered automatically to the first member on the waitlist.',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: mutedTextColor,
                                                fontSize: 12,
                                                height: 1.45,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Safe Public Meeting Guarantee ──
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? AppColors.darkSurface
                                                : AppColors.sage)
                                            .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.shield_outlined,
                                        color: isDark
                                            ? AppColors.luminousMauve
                                            : AppColors.mauve,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Safe Public Meeting Guarantee',
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                    color: primaryTextColor,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Every in-person MELSAVA experience occurs strictly in vetted public spaces. No private addresses or GPS tracking. After the meetup, participants choose privately who they want to reconnect with.',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: primaryTextColor,
                                                    fontSize: 12,
                                                    height: 1.45,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Bottom clearance for sticky bar
                                const SizedBox(height: 110),
                              ],
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

          // ── Floating Action Buttons (Back, Bookmark, Share on Hero) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _buildGlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    color: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),

                  // Actions: Bookmark & Share
                  Row(
                    children: [
                      _buildGlassIconButton(
                        icon: _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isBookmarked
                            ? const Color(0xFFFFB800)
                            : Colors.white,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isBookmarked = !_isBookmarked);
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildGlassIconButton(
                        icon: Icons.ios_share_rounded,
                        color: Colors.white,
                        onTap: () => ExperienceShareSheet.triggerNativeShare(
                          context,
                          exp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Join / Waitlist / Cancel RSVP Bar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? const Color(0xFF130F1E) : Colors.white)
                            .withValues(alpha: 0.65),
                        (isDark ? const Color(0xFF130F1E) : Colors.white)
                            .withValues(alpha: 0.92),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE5DEED).withValues(alpha: 0.55),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: _buildStickyBottomBar(exp, isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(ExperienceModel exp, bool isDark) {
    if (exp.isPast) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          exp.isAttended ? 'Attended ✓' : 'Experience Ended',
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.darkMutedText : AppColors.deepPlum,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (exp.isAttended) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          'Attended ✓',
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (exp.hasJoined) {
      return Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                Navigator.of(context).pop();
                ExperienceHubSheet.show(context, experience: exp);
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hub_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Open Hub',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _isCancelling ? null : () => _confirmCancel(exp),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D1822)
                    : const Color(0xFFFDE8EC),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFEF4444),
                      ),
                    )
                  : const Text(
                      'Cancel RSVP',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    if (exp.isWaitlisted) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkElevated
                    : const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF4C366B)
                      : const Color(0xFFD8B4FE),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.brightViolet
                        : AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'On Waitlist',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.brightViolet
                          : AppColors.primaryPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _isCancelling ? null : () => _confirmCancel(exp),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D1822)
                    : const Color(0xFFFDE8EC),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFEF4444),
                      ),
                    )
                  : const Text(
                      'Leave Waitlist',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    // Default: Join Experience or Join Waitlist
    final isWaitlist = exp.isFull;
    return GestureDetector(
      onTap: () => _openJoinFlow(exp),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.sunsetCtaGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E7E).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          isWaitlist ? 'Join Waitlist →' : 'Join Experience →',
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityHeroPill(ExperienceModel exp, bool isDark) {
    if (exp.hasUnlimitedCapacity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Text(
          'Open Capacity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isFull = exp.isFull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFull
            ? const Color(0xFF7C3AED).withValues(alpha: 0.90)
            : const Color(0xFFEF4444).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
        ],
      ),
      child: Text(
        isFull
            ? (exp.waitlistCount > 0
                  ? '${exp.waitlistCount} on waitlist'
                  : 'Waitlist Open')
            : '${exp.spotsLeft} spots left',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes / 60;
    if (minutes % 60 == 0) return '${hours.toInt()} hrs';
    return '${hours.toStringAsFixed(1)} hrs';
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    bool isDark,
    Color mutedTextColor,
    Color primaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E0EE),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF4C366B) : const Color(0xFFE9D5FF),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Exact Asymmetrical Wave Clipper cloned from user Image 3:
/// - Left side stays elevated (convex crest arching under the title text)
/// - Right side smoothly slopes downward in an organic S-curve
class _OrganicWaveClipper extends CustomClipper<Path> {
  const _OrganicWaveClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Start at top-left: rounded smooth start
    path.moveTo(0, 18);
    path.quadraticBezierTo(0, 0, 18, 0);

    // Convex crest across left and center (where the title text sits)
    path.cubicTo(w * 0.25, 0, w * 0.48, 4, w * 0.65, 12);

    // Graceful organic slope downward to the right edge
    path.cubicTo(w * 0.80, 20, w * 0.94, 34, w, 36);

    // Complete rectangle bounds
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Ambient 3D stroke highlight along the exact wave crest
class _OrganicWaveBorderPainter extends CustomPainter {
  final bool isDark;
  final Color borderColor;

  _OrganicWaveBorderPainter({required this.isDark, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    final path = Path();
    path.moveTo(0, 18);
    path.quadraticBezierTo(0, 0, 18, 0);
    path.cubicTo(w * 0.25, 0, w * 0.48, 4, w * 0.65, 12);
    path.cubicTo(w * 0.80, 20, w * 0.94, 34, w, 36);

    // Soft drop shadow beneath wave crest
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, shadowPaint);

    // Illuminated top accent stroke
    final strokePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          (isDark ? Colors.white : const Color(0xFFFFB300)).withValues(
            alpha: 0.5,
          ),
          (isDark ? const Color(0xFFC084FC) : const Color(0xFFFF6584))
              .withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, 40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _OrganicWaveBorderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
