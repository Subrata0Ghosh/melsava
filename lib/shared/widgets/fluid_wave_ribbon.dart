import 'package:flutter/material.dart';

/// Fluid, multi-layered organic wavy ribbons
///
/// Matches the reference artwork with smooth overlapping cubic bezier curves
/// transitioning from sunset amber to hot coral, vivid magenta, and deep purple.
class FluidWaveRibbon extends StatelessWidget {
  final double height;
  final bool flip;
  final double opacity;

  const FluidWaveRibbon({
    super.key,
    this.height = 110,
    this.flip = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget wave = CustomPaint(
      size: Size(double.infinity, height),
      painter: _FluidWavePainter(),
    );

    if (flip) {
      wave = Transform.scale(scaleY: -1, child: wave);
    }

    if (opacity < 1.0) {
      wave = Opacity(opacity: opacity, child: wave);
    }

    return SizedBox(height: height, width: double.infinity, child: wave);
  }
}

class _FluidWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Layer 1 (Back Wave): Deep Violet to Royal Purple ────────────────
    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.cubicTo(w * 0.22, h * 0.15, w * 0.48, h * 0.85, w * 0.75, h * 0.35);
    path1.cubicTo(w * 0.88, h * 0.12, w * 0.95, h * 0.20, w, h * 0.15);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8A2BE2), Color(0xFF4B1A7C), Color(0xFF280B45)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path1, paint1);

    // ── Layer 2 (Middle Wave): Hot Coral to Vivid Magenta ───────────────
    final path2 = Path();
    path2.moveTo(0, h * 0.60);
    path2.cubicTo(w * 0.20, h * 0.35, w * 0.42, h * 0.95, w * 0.68, h * 0.50);
    path2.cubicTo(w * 0.84, h * 0.25, w * 0.94, h * 0.40, w, h * 0.30);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFF3366), Color(0xFFE040FB), Color(0xFF7C4DFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path2, paint2);

    // ── Layer 3 (Front Wave): Sunset Amber to Radiant Coral ────────────
    final path3 = Path();
    path3.moveTo(0, h * 0.75);
    path3.cubicTo(w * 0.25, h * 0.55, w * 0.52, h * 0.98, w * 0.78, h * 0.68);
    path3.cubicTo(w * 0.89, h * 0.52, w * 0.96, h * 0.58, w, h * 0.48);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();

    final paint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB300), Color(0xFFFF5722), Color(0xFFFF1744)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
