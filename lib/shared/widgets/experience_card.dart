import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/experience_model.dart';
import 'trending_badge.dart';

/// Premium experience card with immersive image, glassmorphic overlays,
/// and smooth micro-interactions. Inspired by Event Discovery (Dribbble)
/// and Social Meetup patterns — NOT a swipe card.
class ExperienceCard extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback onTap;
  final VoidCallback? onJoinTap;
  final bool isCompact;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
    this.onJoinTap,
    this.isCompact = false,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');
    final isFull = exp.currentParticipants >= exp.maxParticipants;
    final spotsLeft = exp.maxParticipants - exp.currentParticipants;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : AppColors.deepPlum.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Hero Image with Gradient + Badges ───
                  _buildHeroImage(isDark, exp, dateFormat, isFull, spotsLeft),

                  // ─── Content Body ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          exp.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.deepPlum,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Venue + Location row
                        _buildInfoRow(
                          Icons.place_rounded,
                          exp.venueName,
                          isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          Icons.schedule_rounded,
                          dateFormat.format(exp.startsAt),
                          isDark,
                        ),

                        const SizedBox(height: 16),

                        // Attendees + Join CTA row
                        Row(
                          children: [
                            // Overlapping avatars
                            _buildAvatarStack(exp, isDark),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${exp.currentParticipants}/${exp.maxParticipants} joined',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.onJoinTap != null)
                              _buildJoinButton(exp, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    bool isDark,
    ExperienceModel exp,
    DateFormat dateFormat,
    bool isFull,
    int spotsLeft,
  ) {
    return SizedBox(
      height: widget.isCompact ? 150 : 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          CachedNetworkImage(
            imageUrl: exp.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkElevated, AppColors.darkSurface]
                      : [AppColors.creamElevated, AppColors.warmIvory],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mauve,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
              child: Icon(
                Icons.image_outlined,
                size: 36,
                color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              ),
            ),
          ),

          // Bottom gradient fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? AppColors.darkSurface : AppColors.white)
                        .withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Category chip — top left
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0E0C14) : Colors.white)
                            .withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(exp.categoryIcon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            exp.categoryName,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.deepPlum,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (exp.currentParticipants >= 8) ...[
                  const SizedBox(width: 6),
                  const TrendingBadge(
                    fontSize: 10,
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  ),
                ],
              ],
            ),
          ),

          // Status badge — top right
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: exp.hasJoined
                    ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                    : (isFull
                        ? AppColors.mutedText
                        : (isDark
                            ? AppColors.vividCoral
                            : AppColors.softCoral)),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                exp.hasJoined
                    ? '✓ Joined'
                    : (isFull ? 'Full' : '$spotsLeft spots left'),
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.luminousMauve.withValues(alpha: 0.12)
                : AppColors.mauve.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isDark ? AppColors.luminousMauve : AppColors.mauve,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack(ExperienceModel exp, bool isDark) {
    final avatars = exp.attendeeAvatars;
    final count = avatars.length.clamp(0, 3);

    return SizedBox(
      height: 30,
      width: (count * 20.0) + 10,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * 20.0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatars[i],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? AppColors.darkElevated : AppColors.sage,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildJoinButton(ExperienceModel exp, bool isDark) {
    final isJoined = exp.hasJoined;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onJoinTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            gradient: isJoined ? null : AppColors.purpleGradient,
            color: isJoined
                ? (isDark ? AppColors.darkElevated : AppColors.creamElevated)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isJoined
                ? Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.divider,
                  )
                : null,
            boxShadow: isJoined
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            isJoined ? 'Joined ✓' : 'Join',
            style: AppTypography.labelSmall.copyWith(
              color: isJoined
                  ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                  : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
