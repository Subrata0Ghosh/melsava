import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// Animated MELSAVA Brand Logo with dynamic stroke-drawing,
/// convergence particle bloom, and luxury brand typography tracking.
///
/// Symbol Meaning ("Why M"):
/// - Left Ribbon: One person's path through the world.
/// - Right Ribbon: Another person's path through the world.
/// - Center Nexus & Anchor: The moment they meet in real life, forming the iconic 'M'.
class AnimatedMelsavaBrandLogo extends StatefulWidget {
  final double size;
  final bool isDark;
  final VoidCallback? onAnimationComplete;

  const AnimatedMelsavaBrandLogo({
    super.key,
    this.size = 110,
    this.isDark = false,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedMelsavaBrandLogo> createState() =>
      _AnimatedMelsavaBrandLogoState();
}

class _AnimatedMelsavaBrandLogoState extends State<AnimatedMelsavaBrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered animation timelines
  late Animation<double> _drawLeftPath;
  late Animation<double> _drawRightPath;
  late Animation<double> _drawCenterPath;
  late Animation<double> _sparkBloom;
  late Animation<double> _logoScale;
  late Animation<double> _wordmarkFade;
  late Animation<double> _wordmarkTracking;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 1. Draw Left Path (Person 1's journey) 0.0 -> 0.45
    _drawLeftPath = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.45, curve: Curves.easeInOutCubic),
    );

    // 2. Draw Right Path (Person 2's journey) 0.15 -> 0.55
    _drawRightPath = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.55, curve: Curves.easeInOutCubic),
    );

    // 3. Central Anchor flows down 0.45 -> 0.70
    _drawCenterPath = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.70, curve: Curves.easeOutBack),
    );

    // 4. Nexus Jewel Spark & Bloom 0.50 -> 0.75
    _sparkBloom = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.75, curve: Curves.elasticOut),
    );

    // 5. Breathing scale of the combined M symbol 0.55 -> 0.85
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 6. Wordmark "M E L S A V A" reveal 0.60 -> 0.88
    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.85, curve: Curves.easeIn),
    );
    _wordmarkTracking = Tween<double>(begin: 10.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    // 7. Philosophy Tagline reveal 0.75 -> 1.0
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Ambient Glow (Behind Logo)
            Transform.scale(
              scale: _logoScale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle Radial Glow
                  if (_sparkBloom.value > 0)
                    Opacity(
                      opacity: (_sparkBloom.value * 0.45).clamp(0.0, 1.0),
                      child: Container(
                        width: widget.size * 1.5,
                        height: widget.size * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              isDark
                                  ? AppColors.luminousMauve.withValues(alpha: 0.4)
                                  : AppColors.softCoral.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Animated Vector Path Logo
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DynamicStrokeMelsavaPainter(
                      leftProgress: _drawLeftPath.value,
                      rightProgress: _drawRightPath.value,
                      centerProgress: _drawCenterPath.value,
                      sparkProgress: _sparkBloom.value,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingLG),

            // Wordmark: M E L S A V A
            Opacity(
              opacity: _wordmarkFade.value,
              child: Text(
                AppConstants.appName,
                style: AppTypography.displayMedium.copyWith(
                  letterSpacing: _wordmarkTracking.value,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingSM),

            // Narrative Philosophy Justification
            Opacity(
              opacity: _taglineFade.value,
              child: Column(
                children: [
                  Text(
                    'TWO PATHS • ONE MOMENT',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Meet through shared experiences.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter that trims and renders bezier curve paths in real-time
class _DynamicStrokeMelsavaPainter extends CustomPainter {
  final double leftProgress;
  final double rightProgress;
  final double centerProgress;
  final double sparkProgress;
  final bool isDark;

  _DynamicStrokeMelsavaPainter({
    required this.leftProgress,
    required this.rightProgress,
    required this.centerProgress,
    required this.sparkProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.125;

    final color1 = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final color2 = isDark ? const Color(0xFFC7A3EC) : AppColors.mauve;
    final color3 = isDark ? AppColors.vividCoral : AppColors.softCoral;

    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paint3 = Paint()
      ..color = color3
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Full geometry paths
    final fullLeftPath = Path()
      ..moveTo(w * 0.18, h * 0.82)
      ..cubicTo(w * 0.15, h * 0.35, w * 0.32, h * 0.18, w * 0.50, h * 0.52);

    final fullRightPath = Path()
      ..moveTo(w * 0.82, h * 0.82)
      ..cubicTo(w * 0.85, h * 0.35, w * 0.68, h * 0.18, w * 0.50, h * 0.52);

    final fullCenterPath = Path()
      ..moveTo(w * 0.50, h * 0.52)
      ..cubicTo(w * 0.50, h * 0.68, w * 0.50, h * 0.78, w * 0.50, h * 0.85);

    // 1. Draw animated left path
    if (leftProgress > 0) {
      final animatedLeft = _extractPartialPath(fullLeftPath, leftProgress);
      canvas.drawPath(animatedLeft, paint1);
    }

    // 2. Draw animated right path
    if (rightProgress > 0) {
      final animatedRight = _extractPartialPath(fullRightPath, rightProgress);
      canvas.drawPath(animatedRight, paint2);
    }

    // 3. Draw animated center path
    if (centerProgress > 0) {
      final animatedCenter = _extractPartialPath(fullCenterPath, centerProgress);
      canvas.drawPath(animatedCenter, paint3);
    }

    // 4. Draw central nexus jewel and meeting spark
    if (sparkProgress > 0) {
      final sparkScale = sparkProgress.clamp(0.0, 1.0);
      final jewelOffset = Offset(w * 0.50, h * 0.52);

      // Outer glow ring
      final glowPaint = Paint()
        ..color = color3.withValues(alpha: (0.35 * (1.0 - sparkScale * 0.3)).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(jewelOffset, strokeWidth * (0.8 + 0.6 * sparkScale), glowPaint);

      // Core connection jewel
      final coreJewelPaint = Paint()
        ..color = color3
        ..style = PaintingStyle.fill;
      canvas.drawCircle(jewelOffset, strokeWidth * 0.68 * sparkScale, coreJewelPaint);

      // White hot center spark
      final whiteSparkPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.9 * sparkScale).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(jewelOffset, strokeWidth * 0.28 * sparkScale, whiteSparkPaint);
    }
  }

  Path _extractPartialPath(Path source, double progress) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      final targetLength = metric.length * progress.clamp(0.0, 1.0);
      result.addPath(metric.extractPath(0, targetLength), Offset.zero);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _DynamicStrokeMelsavaPainter oldDelegate) {
    return oldDelegate.leftProgress != leftProgress ||
        oldDelegate.rightProgress != rightProgress ||
        oldDelegate.centerProgress != centerProgress ||
        oldDelegate.sparkProgress != sparkProgress ||
        oldDelegate.isDark != isDark;
  }
}
