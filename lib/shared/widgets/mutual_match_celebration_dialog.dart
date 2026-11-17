import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Celebratory Mutual Match Dialog inspired by Bean58 & BlindLove (Dribbble).
///
/// Triggers when two attendees mutually select each other (Dating or Friendship)
/// after attending an experience together.
class MutualMatchCelebrationDialog extends StatefulWidget {
  final String userName;
  final String userAvatarUrl;
  final String matchName;
  final String matchAvatarUrl;
  final String mutualIntention; // 'Exploring Dating' or 'Friendship'
  final String experienceTitle;

  const MutualMatchCelebrationDialog({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    required this.matchName,
    required this.matchAvatarUrl,
    required this.mutualIntention,
    required this.experienceTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String userName,
    required String userAvatarUrl,
    required String matchName,
    required String matchAvatarUrl,
    required String mutualIntention,
    required String experienceTitle,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MutualMatchCelebrationDialog(
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        matchName: matchName,
        matchAvatarUrl: matchAvatarUrl,
        mutualIntention: mutualIntention,
        experienceTitle: experienceTitle,
      ),
    );
  }

  @override
  State<MutualMatchCelebrationDialog> createState() =>
      _MutualMatchCelebrationDialogState();
}

class _MutualMatchCelebrationDialogState
    extends State<MutualMatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _confettiAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Animated Confetti Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confettiAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Main Card
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1528) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? AppColors.luminousMauve.withValues(alpha: 0.35)
                      : AppColors.softCoral.withValues(alpha: 0.40),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.luminousMauve : AppColors.mauve)
                        .withValues(alpha: 0.35),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7A60), Color(0xFFA67FD6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "IT'S A MUTUAL MATCH!",
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dual Overlapping Profile Cards with Heart Jewel
                  SizedBox(
                    height: 110,
                    width: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left User Avatar
                        Positioned(
                          left: 10,
                          child: _buildAvatarCard(
                            widget.userAvatarUrl,
                            isDark ? AppColors.luminousMauve : AppColors.mauve,
                          ),
                        ),

                        // Right Match Avatar
                        Positioned(
                          right: 10,
                          child: _buildAvatarCard(
                            widget.matchAvatarUrl,
                            AppColors.vividCoral,
                          ),
                        ),

                        // Center Floating Nexus Heart
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF140F20) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.vividCoral,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.vividCoral.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              color: AppColors.vividCoral,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Headline
                  Text(
                    'You and ${widget.matchName}\nUnlocked Mutual Connection!',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkElevated
                          : AppColors.sage.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Both chose: "${widget.mutualIntention}" from ${widget.experienceTitle}',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.softCoral : AppColors.deepPlum,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Direct chat is now unlocked. Say hello and continue the conversation from where you left off!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.divider,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/connections');
                          },
                          child: Text(
                            'Connections',
                            style: TextStyle(
                              color: mutedTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push('/chat/${widget.matchName}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppColors.sunsetCtaGradient,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5A78).withValues(alpha: 0.40),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Start Chat 💬',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(String url, Color rimColor) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rimColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: rimColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Custom painter for animated confetti particles
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static final List<_ConfettiParticle> _particles = List.generate(40, (i) {
    final random = math.Random(i * 997);
    return _ConfettiParticle(
      angle: random.nextDouble() * 2 * math.pi,
      distance: 80.0 + random.nextDouble() * 160.0,
      size: 4.0 + random.nextDouble() * 6.0,
      color: [
        const Color(0xFFFF7A60),
        const Color(0xFFA67FD6),
        const Color(0xFF67B99A),
        const Color(0xFFFFD166),
        const Color(0xFF06D6A0),
      ][i % 5],
      rotation: random.nextDouble() * math.pi,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);

    for (final p in _particles) {
      final currentDist = p.distance * progress;
      final dx = center.dx + currentDist * math.cos(p.angle);
      final dy = center.dy + currentDist * math.sin(p.angle);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + progress * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double rotation;

  _ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.rotation,
  });
}
