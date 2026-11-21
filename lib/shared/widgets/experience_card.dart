import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/experience_model.dart';
import 'app_smart_image.dart';
import 'trending_badge.dart';

/// Creative Sculptural Experience Card
/// Features an organic, curvish wave transition between hero image and card body,
/// layered ambient shadows, frosted glass badges, and smooth tactile micro-interactions.
class ExperienceCard extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback onTap;
  final VoidCallback? onJoinTap;
  final bool isCompact;
  final bool isHostFollowed;
  final Widget? footer;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
    this.onJoinTap,
    this.isCompact = false,
    this.isHostFollowed = false,
    this.footer,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isBookmarked = false;

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
    final isFull = exp.isFull;
    final spotsLeft = exp.spotsLeft;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.divider.withValues(alpha: 0.7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.primaryPurple.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              color: cardBg,
              child: Stack(
                children: [
                  // Subtle decorative leaf accent in bottom-right corner
                  Positioned(
                    bottom: -15,
                    right: -10,
                    child: Opacity(
                      opacity: isDark ? 0.04 : 0.06,
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 110,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Hero Image with Sculptural Curvish Wave Transition ───
                      _buildHeroImage(
                        isDark,
                        exp,
                        dateFormat,
                        isFull,
                        spotsLeft,
                        cardBg,
                      ),

                      // ─── Content Body ───
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              exp.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 18.5,
                                height: 1.25,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Venue + Location row with squircle icon
                            _buildInfoRow(
                              icon: exp.isOnline
                                  ? Icons.videocam_outlined
                                  : Icons.place_rounded,
                              iconBg:
                                  (isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple)
                                      .withValues(alpha: 0.12),
                              iconColor: isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple,
                              text: exp.isOnline
                                  ? 'Online Experience'
                                  : (exp.venueName.isNotEmpty
                                        ? exp.venueName
                                        : (exp.city.isNotEmpty
                                              ? exp.city
                                              : 'Public Venue')),
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              mutedTextColor: mutedTextColor,
                            ),
                            const SizedBox(height: 8),

                            // Time row with squircle icon
                            _buildInfoRow(
                              icon: Icons.schedule_rounded,
                              iconBg: const Color(
                                0xFFFF9800,
                              ).withValues(alpha: 0.12),
                              iconColor: const Color(0xFFFF9800),
                              text: dateFormat.format(exp.startsAt),
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              mutedTextColor: mutedTextColor,
                            ),

                            const SizedBox(height: 18),

                            // Attendees + Capacity Pill + Join CTA row
                            Row(
                              children: [
                                // Overlapping avatars stack
                                _buildAvatarStack(exp, isDark, cardBg),
                                const SizedBox(width: 10),

                                // Joined capacity count
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFull
                                              ? AppColors.error
                                              : AppColors.mintAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        exp.hasUnlimitedCapacity
                                            ? '${exp.currentParticipants} joined'
                                            : '${exp.currentParticipants}/${exp.maxParticipants} joined',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: mutedTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Join Button (hidden when custom footer is supplied)
                                if (widget.onJoinTap != null &&
                                    widget.footer == null)
                                  _buildJoinButton(exp, isDark),
                              ],
                            ),

                            // Integrated Card Action Footer
                            if (widget.footer != null) ...[
                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                thickness: 0.9,
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.divider.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              widget.footer!,
                            ],
                          ],
                        ),
                      ),
                    ],
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
    Color cardBg,
  ) {
    return SizedBox(
      height: widget.isCompact ? 165 : 205,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo ──────────────────────────────────────────────────────────
          AppSmartImage(
            imagePath: exp.coverImageUrl,
            categoryHint: '${exp.title} ${exp.categoryName}',
            fit: BoxFit.cover,
            placeholder: Container(
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
          ),

          // ── Top Gradient Vignette (Improves badge readability) ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Sculptural Curvish Wave Transition (Boundary to Content) ────────
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            height: 42,
            child: CustomPaint(
              painter: _CurvedWaveTransitionPainter(
                cardColor: cardBg,
                accentColor: isDark
                    ? AppColors.brightViolet
                    : AppColors.primaryPurple,
              ),
            ),
          ),

          // ── Category Chip & Trending Badge (Top Left) ──────────────────────
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF151022) : Colors.white)
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exp.categoryIcon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            exp.categoryName,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.deepPlum,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (exp.currentParticipants >= 8) ...[
                  const SizedBox(width: 7),
                  const TrendingBadge(
                    fontSize: 10.5,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  ),
                ],
                if (widget.isHostFollowed) ...[
                  const SizedBox(width: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.softCoral
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Followed Host',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Spots Left Badge & Bookmark Icon (Top Right) ────────────────────
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: exp.hasJoined
                        ? AppColors.purpleGradient
                        : (isFull
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7A60),
                                    Color(0xFFFF5252),
                                  ],
                                )),
                    color: (!exp.hasJoined && isFull)
                        ? AppColors.mutedText
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    exp.hasJoined
                        ? '✓ Joined'
                        : (isFull ? 'Full' : '$spotsLeft spots left'),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isBookmarked = !_isBookmarked);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          _isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: _isBookmarked
                              ? const Color(0xFFFFB300)
                              : Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String text,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: mutedTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack(ExperienceModel exp, bool isDark, Color cardBg) {
    final avatars = exp.attendeeAvatars;
    final count = avatars.length.clamp(0, 3);

    return SizedBox(
      height: 32,
      width: (count * 20.0) + 12,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * 20.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cardBg, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: AppSmartImage(
                  imagePath: avatars[i],
                  isAvatar: true,
                  fit: BoxFit.cover,
                  placeholder: Container(
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
    final isAttended = exp.isAttended;
    final isWaitlisted = exp.isWaitlisted;
    final isMember = isJoined || isWaitlisted || isAttended;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onJoinTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
          decoration: BoxDecoration(
            gradient: (isJoined || !isMember)
                ? (isJoined
                      ? AppColors.purpleGradient
                      : AppColors.sunsetCtaGradient)
                : null,
            color: isMember && !isJoined
                ? (isDark ? AppColors.darkElevated : AppColors.creamElevated)
                : null,
            borderRadius: BorderRadius.circular(18),
            border: isMember && !isJoined
                ? Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.divider,
                  )
                : null,
            boxShadow: isJoined || !isMember
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isJoined) ...[
                const Icon(Icons.hub_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                isAttended
                    ? 'Reconnect →'
                    : (isJoined
                          ? 'Open Hub'
                          : (isWaitlisted
                                ? 'Waitlisted'
                                : (exp.isFull ? 'Waitlist' : 'Join'))),
                style: AppTypography.labelSmall.copyWith(
                  color: isMember && !isJoined
                      ? (isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple)
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              if (!isMember) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SCULPTURAL CURVISH WAVE TRANSITION PAINTER
/// Replaces the flat horizontal line with an organic, flowing wave transition,
/// featuring a glowing specular accent crest and depth drop shadow.
/// ─────────────────────────────────────────────────────────────────────────────
class _CurvedWaveTransitionPainter extends CustomPainter {
  final Color cardColor;
  final Color accentColor;

  _CurvedWaveTransitionPainter({
    required this.cardColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Curvish Wave Path Definition matching Image 3:
    // Left & center arch upward in a convex crest under the title, then slope gracefully down to the right.
    Path createWavePath({double offsetY = 0}) {
      final p = Path();
      p.moveTo(0, 14.0 + offsetY);
      p.cubicTo(
        w * 0.25,
        2.0 + offsetY,
        w * 0.50,
        4.0 + offsetY,
        w * 0.65,
        10.0 + offsetY,
      );
      p.cubicTo(
        w * 0.80,
        16.0 + offsetY,
        w * 0.94,
        25.0 + offsetY,
        w,
        26.0 + offsetY,
      );
      p.lineTo(w, h + 3.0);
      p.lineTo(0, h + 3.0);
      p.close();
      return p;
    }

    // 2. Soft Drop Shadow Beneath the Wave (Elevates the card body above the photo)
    final shadowPath = createWavePath(offsetY: -3.0);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawPath(shadowPath, shadowPaint);

    // 3. Subtle Glowing Accent Crest Line
    final crestPath = Path()
      ..moveTo(0, 14.0)
      ..cubicTo(w * 0.25, 2.0, w * 0.50, 4.0, w * 0.65, 10.0)
      ..cubicTo(w * 0.80, 16.0, w * 0.94, 25.0, w, 26.0);

    final crestGlowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(crestPath, crestGlowPaint);

    final crestStrokePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.90),
          accentColor.withValues(alpha: 0.50),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(crestPath, crestStrokePaint);

    // 4. Solid Card Body Fill (Merges seamlessly with the content padding below)
    final fillPath = createWavePath();
    final fillPaint = Paint()
      ..color = cardColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedWaveTransitionPainter oldDelegate) =>
      oldDelegate.cardColor != cardColor ||
      oldDelegate.accentColor != accentColor;
}
