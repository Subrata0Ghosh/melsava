import 'package:flutter/material.dart';

enum BotanicalLeafStyle {
  monstera,
  tropicalFoliage,
}

/// Botanical Leaf Accents for cards and modal sheets
///
/// Matches the prototype images where lush monstera leaves and tropical foliage
/// peek out organically from behind card edges.
class BotanicalLeafDecoration extends StatelessWidget {
  final BotanicalLeafStyle style;
  final double width;
  final double height;
  final double rotation;
  final double opacity;

  const BotanicalLeafDecoration({
    super.key,
    this.style = BotanicalLeafStyle.monstera,
    this.width = 65,
    this.height = 110,
    this.rotation = 0.0,
    this.opacity = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    Widget leaf = CustomPaint(
      size: Size(width, height),
      painter: style == BotanicalLeafStyle.monstera
          ? _MonsteraLeafPainter()
          : _TropicalFoliagePainter(),
    );

    if (rotation != 0.0) {
      leaf = Transform.rotate(
        angle: rotation,
        child: leaf,
      );
    }

    if (opacity < 1.0) {
      leaf = Opacity(opacity: opacity, child: leaf);
    }

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: leaf,
      ),
    );
  }
}

/// Custom painter for Monstera leaf with deep slits and vein lines
class _MonsteraLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    // Start at bottom stem/base
    path.moveTo(w * 0.1, h * 0.95);
    // Left edge lobes
    path.cubicTo(w * 0.0, h * 0.80, w * 0.05, h * 0.65, w * 0.20, h * 0.55);
    path.cubicTo(w * 0.10, h * 0.50, w * 0.15, h * 0.35, w * 0.35, h * 0.25);
    path.cubicTo(w * 0.30, h * 0.15, w * 0.50, h * 0.02, w * 0.70, h * 0.0);
    // Tip
    path.cubicTo(w * 0.85, h * 0.0, w * 0.98, h * 0.15, w * 0.92, h * 0.30);
    // Right edge lobes with characteristic cutouts / slits
    path.cubicTo(w * 0.70, h * 0.35, w * 0.95, h * 0.45, w * 0.88, h * 0.60);
    path.cubicTo(w * 0.65, h * 0.62, w * 0.85, h * 0.75, w * 0.75, h * 0.88);
    path.cubicTo(w * 0.55, h * 0.85, w * 0.35, h * 0.98, w * 0.1, h * 0.95);
    path.close();

    // Draw shadow first
    canvas.save();
    canvas.translate(2, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Main leaf body gradient: lush spring lime to emerald forest green
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF9CCC65), // light spring green
          Color(0xFF7CB342), // vibrant green
          Color(0xFF43A047), // rich leaf green
          Color(0xFF2E7D32), // deep forest green
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, leafPaint);

    // Draw main central stem vein
    final veinPaint = Paint()
      ..color = const Color(0xFFC5E1A5).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final veinPath = Path();
    veinPath.moveTo(w * 0.15, h * 0.92);
    veinPath.cubicTo(w * 0.35, h * 0.65, w * 0.55, h * 0.35, w * 0.70, h * 0.02);
    canvas.drawPath(veinPath, veinPaint);

    // Secondary veins branching out
    final subVeinPaint = Paint()
      ..color = const Color(0xFFC5E1A5).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.30, h * 0.70), Offset(w * 0.15, h * 0.58), subVeinPaint);
    canvas.drawLine(Offset(w * 0.38, h * 0.58), Offset(w * 0.72, h * 0.50), subVeinPaint);
    canvas.drawLine(Offset(w * 0.45, h * 0.45), Offset(w * 0.25, h * 0.35), subVeinPaint);
    canvas.drawLine(Offset(w * 0.52, h * 0.32), Offset(w * 0.80, h * 0.25), subVeinPaint);

    // Subtle edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for layered tropical foliage fronds (palm & banana leaves)
class _TropicalFoliagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw 3 layered fronds
    _drawFrond(
      canvas,
      base: Offset(w * 0.1, h * 0.9),
      tip: Offset(w * 0.85, h * 0.15),
      ctrl: Offset(w * 0.4, h * 0.3),
      width: w * 0.35,
      colors: const [Color(0xFF81C784), Color(0xFF388E3C), Color(0xFF1B5E20)],
    );

    _drawFrond(
      canvas,
      base: Offset(w * 0.2, h * 0.95),
      tip: Offset(w * 0.60, h * 0.05),
      ctrl: Offset(w * 0.25, h * 0.4),
      width: w * 0.28,
      colors: const [Color(0xFFAED581), Color(0xFF689F38), Color(0xFF33691E)],
    );

    _drawFrond(
      canvas,
      base: Offset(w * 0.05, h * 0.85),
      tip: Offset(w * 0.95, h * 0.45),
      ctrl: Offset(w * 0.5, h * 0.6),
      width: w * 0.25,
      colors: const [Color(0xFFC5E1A5), Color(0xFF7CB342), Color(0xFF2E7D32)],
    );
  }

  void _drawFrond(
    Canvas canvas, {
    required Offset base,
    required Offset tip,
    required Offset ctrl,
    required double width,
    required List<Color> colors,
  }) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(ctrl.dx - width * 0.5, ctrl.dy, tip.dx, tip.dy);
    path.quadraticBezierTo(ctrl.dx + width * 0.5, ctrl.dy, base.dx, base.dy);
    path.close();

    canvas.save();
    canvas.translate(1.5, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: colors,
      ).createShader(Rect.fromPoints(base, tip));
    canvas.drawPath(path, paint);

    // Spine
    final spinePaint = Paint()
      ..color = const Color(0xFFDCEDC8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final spine = Path();
    spine.moveTo(base.dx, base.dy);
    spine.quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
    canvas.drawPath(spine, spinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
