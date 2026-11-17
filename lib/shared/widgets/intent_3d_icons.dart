import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 3D INTENT ICONS & CLAYMORPHIC GRAPHICS
/// Custom-crafted volumetric 3D vector graphics with specular highlights,
/// directional extrusion depth, and ambient contact shadows.
/// ─────────────────────────────────────────────────────────────────────────────

/// 1. 3D Friendship Icon (Volumetric Duo with Overlapping Depth)
class Friendship3DIcon extends StatelessWidget {
  final double size;

  const Friendship3DIcon({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Friendship3DPainter(),
      ),
    );
  }
}

class _Friendship3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // ── 1. Contact Floor Shadow ───────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x380288D1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 43), width: 34, height: 7),
      shadowPaint,
    );

    // ── 2. Figure 1 (Left - Background Companion) ────────────────────────────
    // Torso 3D Extrusion
    final torso1Depth = Path()
      ..moveTo(8, 41)
      ..quadraticBezierTo(9, 28, 17, 26)
      ..quadraticBezierTo(25, 28, 26, 41)
      ..close();
    canvas.drawPath(
      torso1Depth.shift(const Offset(0, 1.8)),
      Paint()..color = const Color(0xFF0D47A1),
    );

    // Torso 1 Face
    final torso1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64B5F6), Color(0xFF1976D2), Color(0xFF0D47A1)],
      ).createShader(const Rect.fromLTWH(8, 26, 18, 15));
    canvas.drawPath(torso1Depth, torso1Paint);

    // Head 1 (Spherical 3D Ball)
    final head1Center = const Offset(17, 18);
    // Head 1 shadow
    canvas.drawCircle(
      head1Center.translate(0, 1.5),
      7.5,
      Paint()..color = const Color(0xFF0D47A1),
    );
    // Head 1 body
    final head1Paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [Color(0xFFBBDEFB), Color(0xFF2196F3), Color(0xFF0D47A1)],
      ).createShader(Rect.fromCircle(center: head1Center, radius: 7.5));
    canvas.drawCircle(head1Center, 7.5, head1Paint);

    // Head 1 Specular Highlight
    final glint1Paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(head1Center.translate(-2.5, -2.5), 1.8, glint1Paint);

    // ── 3. Separation Shadow Cast on Left Figure ──────────────────────────────
    final separationShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(const Offset(29, 14), 10.5, separationShadow);

    // ── 4. Figure 2 (Right - Foreground Leader) ──────────────────────────────
    // Torso 2 3D Extrusion
    final torso2Depth = Path()
      ..moveTo(19, 41)
      ..quadraticBezierTo(21, 24, 30, 22)
      ..quadraticBezierTo(39, 24, 41, 41)
      ..close();
    canvas.drawPath(
      torso2Depth.shift(const Offset(0, 2.2)),
      Paint()..color = const Color(0xFF01579B),
    );

    // Torso 2 Face
    final torso2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF90CAF9), Color(0xFF29B6F6), Color(0xFF0288D1)],
      ).createShader(const Rect.fromLTWH(19, 22, 22, 19));
    canvas.drawPath(torso2Depth, torso2Paint);

    // Torso 2 Top Specular Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white70, Colors.transparent],
      ).createShader(const Rect.fromLTWH(21, 22, 18, 10));
    final torsoRimPath = Path()
      ..moveTo(21, 33)
      ..quadraticBezierTo(21, 24, 30, 22)
      ..quadraticBezierTo(39, 24, 39, 33);
    canvas.drawPath(torsoRimPath, rimPaint);

    // Head 2 (Larger Spherical 3D Ball)
    final head2Center = const Offset(30, 13);
    // Head 2 shadow
    canvas.drawCircle(
      head2Center.translate(0, 1.8),
      9.0,
      Paint()..color = const Color(0xFF01579B),
    );
    // Head 2 body
    final head2Paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [Color(0xFFE3F2FD), Color(0xFF03A9F4), Color(0xFF0277BD)],
      ).createShader(Rect.fromCircle(center: head2Center, radius: 9.0));
    canvas.drawCircle(head2Center, 9.0, head2Paint);

    // Head 2 Specular Catchlight
    canvas.drawCircle(
      head2Center.translate(-3.0, -3.0),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      head2Center.translate(-1.0, -4.2),
      1.0,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 3D Activity Partner Icon (Isometric Volumetric Jigsaw Puzzle Piece)
class ActivityPartner3DIcon extends StatelessWidget {
  final double size;

  const ActivityPartner3DIcon({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ActivityPartner3DPainter(),
      ),
    );
  }
}

class _ActivityPartner3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // ── 1. Contact Floor Shadow ───────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x35E91E63)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 43), width: 34, height: 7),
      shadowPaint,
    );

    // ── 2. Puzzle Outline Path ────────────────────────────────────────────────
    Path createPuzzlePath() {
      final p = Path();
      // Top-left corner
      p.moveTo(12, 16);
      // Top edge with male outward tab
      p.lineTo(20, 16);
      p.cubicTo(19, 10, 29, 10, 28, 16);
      p.lineTo(36, 16);
      // Right edge with male outward tab
      p.lineTo(36, 22);
      p.cubicTo(42, 21, 42, 31, 36, 30);
      p.lineTo(36, 36);
      // Bottom edge with female inward blank
      p.lineTo(28, 36);
      p.cubicTo(29, 30, 19, 30, 20, 36);
      p.lineTo(12, 36);
      // Left edge with female inward blank
      p.lineTo(12, 30);
      p.cubicTo(18, 31, 18, 21, 12, 22);
      p.close();
      return p;
    }

    final puzzlePath = createPuzzlePath();

    // ── 3. 3D Bevel Extrusion (Bottom / Sides) ────────────────────────────────
    for (double dy = 3.0; dy >= 0.5; dy -= 0.5) {
      canvas.drawPath(
        puzzlePath.shift(Offset(0, dy)),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF880E4F),
            const Color(0xFFC2185B),
            (3.0 - dy) / 3.0,
          )!,
      );
    }

    // ── 4. Front Face ─────────────────────────────────────────────────────────
    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7597), Color(0xFFFF2A6D), Color(0xFFD81B60)],
      ).createShader(const Rect.fromLTWH(10, 10, 34, 30));
    canvas.drawPath(puzzlePath, frontPaint);

    // ── 5. Specular Gloss Highlights ──────────────────────────────────────────
    // Gloss on top tab
    final glossTabPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 12), width: 5.5, height: 2.5),
      glossTabPaint,
    );

    // Gloss rim along top-left shoulder
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.transparent],
      ).createShader(const Rect.fromLTWH(12, 16, 24, 20));

    final rimPath = Path()
      ..moveTo(13, 23)
      ..lineTo(13, 17)
      ..lineTo(21, 17);
    canvas.drawPath(rimPath, rimPaint);

    // Subtle inner emboss circle in center
    final centerCorePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(18, 20, 12, 12));
    canvas.drawCircle(const Offset(24, 26), 5, centerCorePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 3D Dating Icon (Volumetric Emerald Energy Lightning Gem with Facet Bevels)
class Dating3DIcon extends StatelessWidget {
  final double size;

  const Dating3DIcon({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Dating3DPainter(),
      ),
    );
  }
}

class _Dating3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // ── 1. Contact Floor Shadow ───────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x3500BFA5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 43), width: 28, height: 6.5),
      shadowPaint,
    );

    // ── 2. Full Lightning Bolt Path ───────────────────────────────────────────
    Path createBoltPath() {
      final p = Path();
      p.moveTo(27, 5);      // Top tip
      p.lineTo(13, 24);     // Outer left mid
      p.lineTo(23, 24);     // Inner left notch
      p.lineTo(18, 43);     // Bottom tip
      p.lineTo(35, 19);     // Outer right mid
      p.lineTo(25, 19);     // Inner right notch
      p.close();
      return p;
    }

    final boltPath = createBoltPath();

    // ── 3. 3D Volumetric Extrusion (Down & Right) ────────────────────────────
    for (double dy = 3.2; dy >= 0.5; dy -= 0.6) {
      canvas.drawPath(
        boltPath.shift(Offset(0.8, dy)),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF004D40),
            const Color(0xFF00796B),
            (3.2 - dy) / 3.2,
          )!,
      );
    }

    // ── 4. Dual-Facet 3D Surface (Light Left Facet, Rich Right Facet) ─────────
    // Base surface
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00B0FF)],
      ).createShader(const Rect.fromLTWH(13, 5, 22, 38));
    canvas.drawPath(boltPath, basePaint);

    // Left Facet (Light caught side)
    final leftFacetPath = Path()
      ..moveTo(27, 5)
      ..lineTo(13, 24)
      ..lineTo(23, 24)
      ..lineTo(18, 43)
      ..lineTo(24, 21.5)
      ..close();
    final leftFacetPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB9F6CA), Color(0xFF00E676)],
      ).createShader(const Rect.fromLTWH(13, 5, 15, 38));
    canvas.drawPath(leftFacetPath, leftFacetPaint);

    // Center Spine Ridge (Bevel highlight)
    final spinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawLine(const Offset(27, 5), const Offset(24, 21.5), spinePaint);
    canvas.drawLine(const Offset(24, 21.5), const Offset(18, 43), spinePaint);

    // ── 5. Specular Glint & Sparkle Stars ─────────────────────────────────────
    // Top glint
    canvas.drawCircle(
      const Offset(26.5, 6.5),
      1.6,
      Paint()..color = Colors.white,
    );

    // Floating 4-Point Diamond Sparkle Star (Top Right)
    void drawSparkle(Offset center, double radius) {
      final sp = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
        ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
        ..close();
      canvas.drawPath(sp, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        radius * 0.4,
        Paint()
          ..color = const Color(0xFFB9F6CA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    drawSparkle(const Offset(37, 10), 4.5);
    drawSparkle(const Offset(11, 33), 3.0);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. 3D Serious Relationship Icon (Volumetric Golden Medal with Ribbon & 3D Star)
class SeriousRelationship3DIcon extends StatelessWidget {
  final double size;

  const SeriousRelationship3DIcon({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SeriousRelationship3DPainter(),
      ),
    );
  }
}

class _SeriousRelationship3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // ── 1. Contact Floor Shadow ───────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x35FF8F00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 43), width: 32, height: 6.5),
      shadowPaint,
    );

    // ── 2. Hanging Ribbon Tails ───────────────────────────────────────────────
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
      ).createShader(const Rect.fromLTWH(12, 24, 24, 18));

    // Left Ribbon
    final leftRibbon = Path()
      ..moveTo(17, 26)
      ..lineTo(14, 41)
      ..lineTo(18, 38)
      ..lineTo(22, 41)
      ..lineTo(23, 26)
      ..close();
    canvas.drawPath(leftRibbon, ribbonPaint);

    // Right Ribbon
    final rightRibbon = Path()
      ..moveTo(25, 26)
      ..lineTo(26, 41)
      ..lineTo(30, 38)
      ..lineTo(34, 41)
      ..lineTo(31, 26)
      ..close();
    canvas.drawPath(rightRibbon, ribbonPaint);

    // ── 3. Medal 3D Extrusion ─────────────────────────────────────────────────
    final medalCenter = const Offset(24, 20);
    const medalRadius = 14.5;

    for (double dy = 3.2; dy >= 0.5; dy -= 0.6) {
      canvas.drawCircle(
        medalCenter.translate(0, dy),
        medalRadius,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFB78103),
            const Color(0xFFFF8F00),
            (3.2 - dy) / 3.2,
          )!,
      );
    }

    // ── 4. Medal Front Coin Surface ───────────────────────────────────────────
    final coinPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.95,
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
        ],
      ).createShader(Rect.fromCircle(center: medalCenter, radius: medalRadius));
    canvas.drawCircle(medalCenter, medalRadius, coinPaint);

    // Sunken Inner Rim (Emboss effect)
    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFF57F17).withValues(alpha: 0.6);
    canvas.drawCircle(medalCenter, medalRadius - 3.0, innerRimPaint);

    // ── 5. Central 3D Faceted Star Relief ─────────────────────────────────────
    void drawFacetedStar(Offset center, double outerRadius, double innerRadius) {
      const int numPoints = 5;
      const double step = math.pi / numPoints;
      final List<Offset> points = [];

      for (int i = 0; i < numPoints * 2; i++) {
        final r = (i % 2 == 0) ? outerRadius : innerRadius;
        final angle = i * step - math.pi / 2;
        points.add(Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ));
      }

      // Draw alternating light and shadow facet triangles for 3D metallic depth
      final lightFacet = Paint()..color = const Color(0xFFFFFDE7);
      final darkFacet = Paint()..color = const Color(0xFFE65100);

      for (int i = 0; i < points.length; i++) {
        final next = (i + 1) % points.length;
        final triangle = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(points[i].dx, points[i].dy)
          ..lineTo(points[next].dx, points[next].dy)
          ..close();

        canvas.drawPath(triangle, (i % 2 == 0) ? lightFacet : darkFacet);
      }
    }

    drawFacetedStar(medalCenter, 7.5, 3.5);

    // ── 6. Specular Coin Flare & Rim Glint ─────────────────────────────────────
    // Top-left rim highlight
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(medalCenter.translate(-7, -7), 2.2, glintPaint);
    canvas.drawCircle(medalCenter.translate(-4.5, -9.5), 1.2, glintPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
