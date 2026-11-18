import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Volumetric 3D claymorphic icons for "Popular Categories" matching Image 2 & Image 6 Screen 5:
/// 1. Social3DIcon: Dual 3D glossy rounded figures (Cyan/Sky Blue)
/// 2. Sports3DIcon: 3D Table tennis paddle & ball (Fiery Orange/Coral)
/// 3. Travel3DIcon: 3D Adventure backpack / compass (Luminous Amber/Gold)
/// 4. Arts3DIcon: 3D Art palette with colorful paint wells & brush (Rich Magenta/Violet)
/// 5. Wellness3DIcon: 3D Lotus flower with layered blooming petals (Royal Purple)
class Category3DIcon extends StatelessWidget {
  final String categoryKey;
  final double size;

  const Category3DIcon({super.key, required this.categoryKey, this.size = 32});

  @override
  Widget build(BuildContext context) {
    switch (categoryKey) {
      case 'Social':
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _Social3DPainter()),
        );
      case 'Sports':
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _Sports3DPainter()),
        );
      case 'Outdoors':
      case 'Travel':
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _Travel3DPainter()),
        );
      case 'Arts & Culture':
      case 'Arts':
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _Arts3DPainter()),
        );
      case 'Wellness':
      default:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _Wellness3DPainter()),
        );
    }
  }
}

/// 1. 3D Social Duo Figures (Image 2 - Social)
class _Social3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x330055AA)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.90),
        width: w * 0.75,
        height: h * 0.18,
      ),
      shadowPaint,
    );

    // Primary Left Figure (Foreground)
    final fgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
    );

    // Secondary Right Figure (Background, slightly higher and darker)
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0284C7), Color(0xFF075985)],
    );

    // Draw Right Head
    final rightHeadCenter = Offset(w * 0.68, h * 0.38);
    final rightHeadRadius = w * 0.16;
    final rightHeadPaint = Paint()
      ..shader = bgGradient.createShader(
        Rect.fromCircle(center: rightHeadCenter, radius: rightHeadRadius),
      );
    canvas.drawCircle(rightHeadCenter, rightHeadRadius, rightHeadPaint);

    // Draw Right Torso
    final rightTorsoPath = Path()
      ..moveTo(w * 0.52, h * 0.85)
      ..quadraticBezierTo(w * 0.54, h * 0.54, w * 0.68, h * 0.54)
      ..quadraticBezierTo(w * 0.82, h * 0.54, w * 0.84, h * 0.85)
      ..close();
    canvas.drawPath(rightTorsoPath, rightHeadPaint);

    // Draw Left Head (Foreground)
    final leftHeadCenter = Offset(w * 0.38, h * 0.32);
    final leftHeadRadius = w * 0.19;
    final leftHeadPaint = Paint()
      ..shader = fgGradient.createShader(
        Rect.fromCircle(center: leftHeadCenter, radius: leftHeadRadius),
      );
    canvas.drawCircle(leftHeadCenter, leftHeadRadius, leftHeadPaint);

    // Left Head Specular 3D Highlight
    final specularPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(
      Offset(w * 0.33, h * 0.27),
      leftHeadRadius * 0.35,
      specularPaint,
    );

    // Draw Left Torso (Foreground dome)
    final leftTorsoPath = Path()
      ..moveTo(w * 0.16, h * 0.88)
      ..quadraticBezierTo(w * 0.20, h * 0.50, w * 0.38, h * 0.50)
      ..quadraticBezierTo(w * 0.56, h * 0.50, w * 0.60, h * 0.88)
      ..close();
    canvas.drawPath(leftTorsoPath, leftHeadPaint);

    // Torso 3D highlight arc
    final torsoHighlight = Path()
      ..moveTo(w * 0.24, h * 0.82)
      ..quadraticBezierTo(w * 0.27, h * 0.56, w * 0.38, h * 0.55);
    final highlightStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(torsoHighlight, highlightStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 3D Sports Paddle & Ball (Image 2 - Sports)
class _Sports3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33D94600)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.70,
        height: h * 0.16,
      ),
      shadowPaint,
    );

    // Paddle Handle (Extruded Wood Bevel)
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDBA74), Color(0xFFC2410C)],
      ).createShader(Rect.fromLTWH(w * 0.40, h * 0.60, w * 0.20, h * 0.32));
    final handleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.74),
        width: w * 0.14,
        height: h * 0.30,
      ),
      const Radius.circular(5),
    );
    canvas.save();
    canvas.translate(w * 0.32, h * 0.74);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-w * 0.32, -h * 0.74);
    canvas.drawRRect(handleRRect, handlePaint);
    canvas.restore();

    // Paddle Blade (3D Rounded Disc in Bright Fiery Orange)
    final bladeCenter = Offset(w * 0.54, h * 0.42);
    final bladeRadius = w * 0.30;
    final bladePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFFF8A4C), Color(0xFFEA580C), Color(0xFF9A3412)],
      ).createShader(Rect.fromCircle(center: bladeCenter, radius: bladeRadius));
    canvas.drawCircle(bladeCenter, bladeRadius, bladePaint);

    // Blade Specular Rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCircle(center: bladeCenter, radius: bladeRadius - 1),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      rimPaint,
    );

    // 3D White/Cream Ball with Specular Light
    final ballCenter = Offset(w * 0.76, h * 0.66);
    final ballRadius = w * 0.12;
    final ballPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        colors: [Colors.white, Color(0xFFFFEDD5), Color(0xFFFDBA74)],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    final ballSpecular = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(w * 0.73, h * 0.63),
      ballRadius * 0.3,
      ballSpecular,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 3D Travel & Outdoor Backpack / Golden Compass (Image 2 - Travel)
class _Travel3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact glow shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33D97706)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.70,
        height: h * 0.18,
      ),
      shadowPaint,
    );

    // Backpack / Compass body
    final bodyCenter = Offset(w * 0.5, h * 0.48);
    final bodyRadius = w * 0.32;
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.3),
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromCircle(center: bodyCenter, radius: bodyRadius));

    // Draw 3D curved rucksack / camp dome
    final domePath = Path()
      ..moveTo(w * 0.22, h * 0.78)
      ..quadraticBezierTo(w * 0.22, h * 0.28, w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.78, h * 0.28, w * 0.78, h * 0.78)
      ..quadraticBezierTo(w * 0.50, h * 0.84, w * 0.22, h * 0.78)
      ..close();
    canvas.drawPath(domePath, bodyPaint);

    // Top Handle Loop
    final loopPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.22),
        width: w * 0.24,
        height: h * 0.16,
      ),
      math.pi,
      math.pi,
      false,
      loopPaint,
    );

    // Front pocket flap
    final pocketPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
      ).createShader(Rect.fromLTWH(w * 0.32, h * 0.52, w * 0.36, h * 0.22));
    final pocketRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.36,
        height: h * 0.22,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(pocketRRect, pocketPaint);

    // 3D Specular Sheen Arc
    final sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.45),
        radius: bodyRadius * 0.8,
      ),
      -math.pi * 0.75,
      math.pi * 0.4,
      false,
      sheenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. 3D Arts Palette & Paint Dots (Image 2 - Arts & Culture)
class _Arts3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft colored shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33A21CAF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.75,
        height: h * 0.18,
      ),
      shadowPaint,
    );

    // Palette base in rich magenta/violet clay
    final palettePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFE879F9), Color(0xFFC026D3), Color(0xFF701A75)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final palettePath = Path()
      ..moveTo(w * 0.20, h * 0.50)
      ..cubicTo(w * 0.18, h * 0.22, w * 0.50, h * 0.18, w * 0.78, h * 0.26)
      ..cubicTo(w * 0.90, h * 0.42, w * 0.84, h * 0.78, w * 0.62, h * 0.82)
      ..cubicTo(w * 0.48, h * 0.84, w * 0.44, h * 0.70, w * 0.36, h * 0.70)
      ..cubicTo(w * 0.26, h * 0.70, w * 0.20, h * 0.72, w * 0.20, h * 0.50)
      ..close();
    canvas.drawPath(palettePath, palettePaint);

    // Specular Rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.36),
        width: w * 0.55,
        height: h * 0.32,
      ),
      -math.pi * 0.9,
      math.pi * 0.65,
      false,
      rimPaint,
    );

    // Colorful 3D paint dots (Yellow, Cyan, White)
    void drawPaintDot(Offset center, Color col1, Color col2) {
      final p = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [col1, col2],
        ).createShader(Rect.fromCircle(center: center, radius: 4));
      canvas.drawCircle(center, 3.8, p);
      canvas.drawCircle(
        center - const Offset(1, 1),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }

    drawPaintDot(
      Offset(w * 0.40, h * 0.34),
      const Color(0xFFFEF08A),
      const Color(0xFFEAB308),
    );
    drawPaintDot(
      Offset(w * 0.60, h * 0.32),
      const Color(0xFFBAE6FD),
      const Color(0xFF0284C7),
    );
    drawPaintDot(
      Offset(w * 0.72, h * 0.48),
      const Color(0xFFFED7AA),
      const Color(0xFFEA580C),
    );

    // Thumb hole
    final holePaint = Paint()..color = const Color(0xFF4A044E);
    canvas.drawCircle(Offset(w * 0.38, h * 0.60), 3.4, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. 3D Wellness Lotus Blossom (Image 2 - Wellness)
class _Wellness3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33581C87)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.70,
        height: h * 0.16,
      ),
      shadowPaint,
    );

    final petalGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC084FC), Color(0xFF7E22CE), Color(0xFF581C87)],
    );

    // Left Petal
    final leftPetal = Path()
      ..moveTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.20, h * 0.66, w * 0.20, h * 0.44)
      ..quadraticBezierTo(w * 0.38, h * 0.42, w * 0.50, h * 0.78)
      ..close();
    final petalPaint = Paint()
      ..shader = petalGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftPetal, petalPaint);

    // Right Petal
    final rightPetal = Path()
      ..moveTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.80, h * 0.66, w * 0.80, h * 0.44)
      ..quadraticBezierTo(w * 0.62, h * 0.42, w * 0.50, h * 0.78)
      ..close();
    canvas.drawPath(rightPetal, petalPaint);

    // Center Tall Petal (Foreground with luminous bevel)
    final centerPetal = Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..quadraticBezierTo(w * 0.68, h * 0.45, w * 0.50, h * 0.80)
      ..quadraticBezierTo(w * 0.32, h * 0.45, w * 0.50, h * 0.18)
      ..close();
    final centerGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE9D5FF), Color(0xFFA855F7), Color(0xFF6B21A8)],
    );
    canvas.drawPath(
      centerPetal,
      Paint()..shader = centerGradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Center Spine Specular Light
    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.24),
      Offset(w * 0.50, h * 0.55),
      spinePaint,
    );

    // Glowing Golden Heart Seed Bead
    final seedCenter = Offset(w * 0.50, h * 0.70);
    final seedPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: seedCenter, radius: 4));
    canvas.drawCircle(seedCenter, 3.5, seedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
