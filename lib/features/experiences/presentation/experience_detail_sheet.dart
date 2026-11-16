import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import 'join_experience_sheet.dart';

/// Screen 2: Experience Details Screen
///
/// High-fidelity experience details inspired by Dribbble Social Meetup
/// (shots/27290057), featuring:
/// - Immersive hero image header with frosted glass action buttons
/// - Modular info cards (Time, Duration, Micro-group size, Vetted Venue)
/// - Interactive Venue preview card with address & map indicator
/// - Attendee roster with vibe tags & host profile
/// - What to Expect / Event itinerary
/// - Sticky bottom bar with Join Experience primary CTA
class ExperienceDetailSheet extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback onToggleJoin;

  const ExperienceDetailSheet({
    super.key,
    required this.experience,
    required this.onToggleJoin,
  });

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
    required VoidCallback onToggleJoin,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExperienceDetailSheet(
        experience: experience,
        onToggleJoin: onToggleJoin,
      ),
    );
  }

  @override
  State<ExperienceDetailSheet> createState() => _ExperienceDetailSheetState();
}

class _ExperienceDetailSheetState extends State<ExperienceDetailSheet> {
  bool _isBookmarked = false;

  void _openJoinFlow() {
    JoinExperienceSheet.show(
      context,
      experience: widget.experience,
      onConfirmed: () {
        widget.onToggleJoin();
        Navigator.of(context).pop(); // Dismiss detail sheet after join
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');
    final spotsLeft = exp.maxParticipants - exp.currentParticipants;

    final sheetBg = isDark ? const Color(0xFF130F1E) : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Drag Pill
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Image with Floating Action Buttons ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: CachedNetworkImage(
                              imageUrl: exp.coverImageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Gradient shading on hero
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.5),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Floating action buttons: Category & Share / Bookmark
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Trending pill badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text('🔥', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Trending',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bookmark & Share Buttons
                              Row(
                                children: [
                                  _buildGlassIconButton(
                                    icon: _isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: _isBookmarked ? AppColors.softCoral : Colors.white,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isBookmarked = !_isBookmarked);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildGlassIconButton(
                                    icon: Icons.share_rounded,
                                    color: Colors.white,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Sharing link to "${exp.title}" copied!'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Bottom spots left indicator
                        Positioned(
                          bottom: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: exp.hasJoined
                                  ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                                  : (spotsLeft <= 0 ? AppColors.mutedText : AppColors.vividCoral),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              exp.hasJoined ? '✓ You\'re RSVPed' : '$spotsLeft spots remaining',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Experience Title & Details ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── 4-Grid Modular Info Cards ──
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.calendar_today_rounded,
                                title: 'Date & Time',
                                subtitle: dateFormat.format(exp.startsAt),
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                mutedTextColor: mutedTextColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.timer_outlined,
                                title: 'Duration',
                                subtitle: '${exp.durationMinutes} minutes',
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                mutedTextColor: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.groups_outlined,
                                title: 'Group Size',
                                subtitle: 'Capped at ${exp.maxParticipants} people',
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                mutedTextColor: mutedTextColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.verified_outlined,
                                title: 'Format',
                                subtitle: 'Vetted Public Spot',
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                mutedTextColor: mutedTextColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── About Section ──
                        Text(
                          'ABOUT THIS EXPERIENCE',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isDark ? AppColors.softCoral : AppColors.mauve,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exp.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: primaryTextColor,
                            fontSize: 14.5,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tags row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTagChip('Outdoor', isDark),
                            _buildTagChip('Adventure', isDark),
                            _buildTagChip('Fitness', isDark),
                            _buildTagChip(exp.categoryName, isDark),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Public Venue Interactive Card ──
                        Text(
                          'VETTED PUBLIC VENUE',
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
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 0.9),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.luminousMauve : AppColors.mauve)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.place_rounded,
                                  color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.venueName,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exp.venueAddress,
                                      style: AppTypography.bodySmall.copyWith(
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
                            color: isDark ? AppColors.softCoral : AppColors.mauve,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 0.9),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                    width: 1.8,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: exp.hostAvatar,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          exp.hostName,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: primaryTextColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
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
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 3),
                                        Text(
                                          '4.8 (124 reviews)',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: mutedTextColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  'Follow',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
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
                            color: (isDark ? AppColors.darkSurface : AppColors.sage)
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Safe Public Meeting Guarantee',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Every MELSAVA experience occurs strictly in vetted public spaces. No private addresses or GPS tracking. After the meetup, participants choose privately who they want to reconnect with.',
                                      style: AppTypography.bodySmall.copyWith(
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

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Bar with CTA ──
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: sheetBg,
                border: Border(top: BorderSide(color: borderColor, width: 0.9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMISSION',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: mutedTextColor,
                        ),
                      ),
                      Text(
                        'Free RSVP',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.softCoral : AppColors.deepPlum,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openJoinFlow,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: exp.hasJoined ? null : AppColors.purpleGradient,
                          color: exp.hasJoined
                              ? (isDark ? AppColors.darkElevated : AppColors.creamElevated)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: exp.hasJoined
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primaryPurple.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Text(
                          exp.hasJoined ? 'Manage RSVP ✓' : 'Join Experience →',
                          style: AppTypography.labelLarge.copyWith(
                            color: exp.hasJoined
                                ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                                : Colors.white,
                            fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: mutedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
