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
    final symbol = CustomPaint(
      size: Size(size, size),
      painter: _MelsavaSymbolPainter(
        color1: primaryColor ?? AppColors.deepPlum,
        color2: accentColor ?? AppColors.mauve,
        color3: highlightColor ?? AppColors.softCoral,
      ),
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
            letterSpacing: 4.0,
            color: primaryColor ?? AppColors.deepPlum,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            AppConstants.primaryTagline,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mutedText,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
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

  _MelsavaSymbolPainter({
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.12;

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

    canvas.drawPath(pathLeft, paint1);
    canvas.drawPath(pathRight, paint2);
    canvas.drawPath(pathCenter, paint3);

    // Subtle central nexus jewel node
    final nodePaint = Paint()
      ..color = AppColors.softCoral
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
        oldDelegate.color3 != color3;
  }
}
