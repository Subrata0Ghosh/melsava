import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// MELSAVA Brand Logo
///
/// Features the custom abstract symbol: 3 flowing paths converging into a
/// central nexus, forming a subtle geometric "M". Can be displayed as:
/// - Standalone symbol
/// - Horizontal lockup with wordmark and tagline
/// - Compact app icon
class MelsavaLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? highlightColor;

  const MelsavaLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.showTagline = false,
    this.primaryColor,
    this.accentColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Luminous adaptive palette:
    // In Dark Mode: Radiant Lavender-Violet, Vivid Sunset Rose, Glowing Peach-Coral
    // In Light Mode: Deep Plum, Mauve, Soft Coral
    final c1 =
        primaryColor ?? (isDark ? const Color(0xFFBA8FFF) : AppColors.deepPlum);
    final c2 =
        accentColor ?? (isDark ? const Color(0xFFE8679A) : AppColors.mauve);
    final c3 =
        highlightColor ??
        (isDark ? const Color(0xFFFF9E73) : AppColors.softCoral);
    final nodeColor = isDark ? const Color(0xFFFF7A8A) : AppColors.softCoral;

    final symbol = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Luminous highlight aura behind symbol
        Container(
          width: size * 0.70,
          height: size * 0.70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFFBA8FFF) : AppColors.primaryPurple)
                        .withValues(alpha: isDark ? 0.38 : 0.16),
                blurRadius: isDark ? 28 : 20,
                spreadRadius: isDark ? 4 : 1,
              ),
              if (isDark)
                BoxShadow(
                  color: const Color(0xFFFF6584).withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(2, 3),
                ),
            ],
          ),
        ),
        CustomPaint(
          size: Size(size, size),
          painter: _MelsavaSymbolPainter(
            color1: c1,
            color2: c2,
            color3: c3,
            nodeColor: nodeColor,
            isDark: isDark,
          ),
        ),
      ],
    );

    if (!showWordmark) return symbol;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        symbol,
        const SizedBox(height: AppConstants.spacingMD),
        Text(
          AppConstants.appName,
          style: AppTypography.displayMedium.copyWith(
            letterSpacing: 4.8,
            color:
                primaryColor ??
                (isDark ? const Color(0xFFF7F5FC) : AppColors.deepPlum),
            fontWeight: FontWeight.w900,
            fontSize: (size * 0.34).clamp(18.0, 32.0),
            shadows: isDark
                ? [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 16,
                    ),
                    Shadow(
                      color: AppColors.brightViolet.withValues(alpha: 0.65),
                      blurRadius: 26,
                    ),
                  ]
                : [
                    Shadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            AppConstants.primaryTagline,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? const Color(0xFFD3CBE2) : AppColors.mutedText,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the MELSAVA brand symbol.
/// Three organic curved ribbons meeting at a central point, forming an abstract 'M'.
class _MelsavaSymbolPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final Color nodeColor;
  final bool isDark;

  _MelsavaSymbolPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.nodeColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.12;

    // Left curved path sweeping up and down into center
    final pathLeft = Path()
      ..moveTo(w * 0.18, h * 0.82)
      ..cubicTo(w * 0.15, h * 0.35, w * 0.32, h * 0.18, w * 0.50, h * 0.52);

    // Right curved path sweeping up and down into center
    final pathRight = Path()
      ..moveTo(w * 0.82, h * 0.82)
      ..cubicTo(w * 0.85, h * 0.35, w * 0.68, h * 0.18, w * 0.50, h * 0.52);

    // Central anchor nexus ribbon
    final pathCenter = Path()
      ..moveTo(w * 0.50, h * 0.52)
      ..cubicTo(w * 0.50, h * 0.70, w * 0.50, h * 0.80, w * 0.50, h * 0.85);

    if (isDark) {
      // Ambient stroke neon bloom in dark mode
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..strokeCap = StrokeCap.round;

      glowPaint.color = color1.withValues(alpha: 0.35);
      canvas.drawPath(pathLeft, glowPaint);

      glowPaint.color = color2.withValues(alpha: 0.35);
      canvas.drawPath(pathRight, glowPaint);

      glowPaint.color = color3.withValues(alpha: 0.35);
      canvas.drawPath(pathCenter, glowPaint);
    }

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

    canvas.drawPath(pathLeft, paint1);
    canvas.drawPath(pathRight, paint2);
    canvas.drawPath(pathCenter, paint3);

    // Subtle central nexus jewel node with specular glow in dark mode
    if (isDark) {
      final nodeGlow = Paint()
        ..color = nodeColor.withValues(alpha: 0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(w * 0.50, h * 0.52),
        strokeWidth * 0.90,
        nodeGlow,
      );
    }

    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.52),
      strokeWidth * 0.65,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MelsavaSymbolPainter oldDelegate) {
    return oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3 ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.isDark != isDark;
  }
}
