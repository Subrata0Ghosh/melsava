import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BotanicalLeafStyle { monstera, tropicalFoliage, eucalyptus, wildGrass }

/// ─────────────────────────────────────────────────────────────────────────────
/// LUSH BOTANICAL NATURE DECORATIONS
/// Realistic, multi-toned leaves, palms, eucalyptus sprigs, and wild grass blades.
/// Supports nuanced green palettes: emerald, olive, mint dew, jade, and sunlit lime.
/// ─────────────────────────────────────────────────────────────────────────────
class BotanicalLeafDecoration extends StatelessWidget {
  final BotanicalLeafStyle style;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final List<Color>? customColors;

  const BotanicalLeafDecoration({
    super.key,
    this.style = BotanicalLeafStyle.monstera,
    this.width = 65,
    this.height = 110,
    this.rotation = 0.0,
    this.opacity = 0.95,
    this.customColors,
  });

  // Presets for varied subtle shades of green
  static const List<Color> emeraldForest = [
    Color(0xFFA5D6A7),
    Color(0xFF66BB6A),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];

  static const List<Color> warmOlive = [
    Color(0xFFE6EE9C),
    Color(0xFFC0CA33),
    Color(0xFF827717),
    Color(0xFF558B2F),
  ];

  static const List<Color> mintDew = [
    Color(0xFFE0F2F1),
    Color(0xFF80CBC4),
    Color(0xFF26A69A),
    Color(0xFF00695C),
  ];

  static const List<Color> goldenSunlit = [
    Color(0xFFFFF59D),
    Color(0xFFDCE775),
    Color(0xFF7CB342),
    Color(0xFF33691E),
  ];

  @override
  Widget build(BuildContext context) {
    Widget leaf;
    switch (style) {
      case BotanicalLeafStyle.monstera:
        leaf = CustomPaint(
          size: Size(width, height),
          painter: _MonsteraLeafPainter(colors: customColors ?? emeraldForest),
        );
        break;
      case BotanicalLeafStyle.tropicalFoliage:
        leaf = CustomPaint(
          size: Size(width, height),
          painter: _TropicalFoliagePainter(
            colors: customColors ?? goldenSunlit,
          ),
        );
        break;
      case BotanicalLeafStyle.eucalyptus:
        leaf = CustomPaint(
          size: Size(width, height),
          painter: _EucalyptusPainter(colors: customColors ?? mintDew),
        );
        break;
      case BotanicalLeafStyle.wildGrass:
        leaf = CustomPaint(
          size: Size(width, height),
          painter: _WildGrassPainter(colors: customColors ?? warmOlive),
        );
        break;
    }

    if (rotation != 0.0) {
      leaf = Transform.rotate(angle: rotation, child: leaf);
    }

    if (opacity < 1.0) {
      leaf = Opacity(opacity: opacity, child: leaf);
    }

    return IgnorePointer(
      child: SizedBox(width: width, height: height, child: leaf),
    );
  }
}

/// 1. Custom painter for Monstera leaf with natural slits and vein lines
class _MonsteraLeafPainter extends CustomPainter {
  final List<Color> colors;

  _MonsteraLeafPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    path.moveTo(w * 0.1, h * 0.95);
    path.cubicTo(w * 0.0, h * 0.80, w * 0.05, h * 0.65, w * 0.20, h * 0.55);
    path.cubicTo(w * 0.10, h * 0.50, w * 0.15, h * 0.35, w * 0.35, h * 0.25);
    path.cubicTo(w * 0.30, h * 0.15, w * 0.50, h * 0.02, w * 0.70, h * 0.0);
    // Tip
    path.cubicTo(w * 0.85, h * 0.0, w * 0.98, h * 0.15, w * 0.92, h * 0.30);
    // Slits
    path.cubicTo(w * 0.70, h * 0.35, w * 0.95, h * 0.45, w * 0.88, h * 0.60);
    path.cubicTo(w * 0.65, h * 0.62, w * 0.85, h * 0.75, w * 0.75, h * 0.88);
    path.cubicTo(w * 0.55, h * 0.85, w * 0.35, h * 0.98, w * 0.1, h * 0.95);
    path.close();

    // Draw shadow first
    canvas.save();
    canvas.translate(2, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Main leaf body gradient
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, leafPaint);

    // Central stem vein
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final veinPath = Path();
    veinPath.moveTo(w * 0.15, h * 0.92);
    veinPath.cubicTo(
      w * 0.35,
      h * 0.65,
      w * 0.55,
      h * 0.35,
      w * 0.70,
      h * 0.02,
    );
    canvas.drawPath(veinPath, veinPaint);

    // Secondary veins branching out
    final subVeinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.30, h * 0.70),
      Offset(w * 0.15, h * 0.58),
      subVeinPaint,
    );
    canvas.drawLine(
      Offset(w * 0.38, h * 0.58),
      Offset(w * 0.72, h * 0.50),
      subVeinPaint,
    );
    canvas.drawLine(
      Offset(w * 0.45, h * 0.45),
      Offset(w * 0.25, h * 0.35),
      subVeinPaint,
    );
    canvas.drawLine(
      Offset(w * 0.52, h * 0.32),
      Offset(w * 0.80, h * 0.25),
      subVeinPaint,
    );

    // Edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _MonsteraLeafPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// 2. Custom painter for layered tropical foliage fronds (palm & banana leaves)
class _TropicalFoliagePainter extends CustomPainter {
  final List<Color> colors;

  _TropicalFoliagePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw 3 layered fronds with nuanced color shifts
    _drawFrond(
      canvas,
      base: Offset(w * 0.1, h * 0.9),
      tip: Offset(w * 0.85, h * 0.15),
      ctrl: Offset(w * 0.4, h * 0.3),
      width: w * 0.35,
      colors: colors,
    );

    _drawFrond(
      canvas,
      base: Offset(w * 0.2, h * 0.95),
      tip: Offset(w * 0.60, h * 0.05),
      ctrl: Offset(w * 0.25, h * 0.4),
      width: w * 0.28,
      colors: colors.reversed.toList(),
    );

    _drawFrond(
      canvas,
      base: Offset(w * 0.05, h * 0.85),
      tip: Offset(w * 0.95, h * 0.45),
      ctrl: Offset(w * 0.5, h * 0.6),
      width: w * 0.25,
      colors: colors,
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

    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final spine = Path();
    spine.moveTo(base.dx, base.dy);
    spine.quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
    canvas.drawPath(spine, spinePaint);
  }

  @override
  bool shouldRepaint(covariant _TropicalFoliagePainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// 3. Custom painter for silver-dollar Eucalyptus sprig (sage, mint & jade discs)
class _EucalyptusPainter extends CustomPainter {
  final List<Color> colors;

  _EucalyptusPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Curved stem
    final stemPaint = Paint()
      ..color = colors.last.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(w * 0.2, h * 0.95);
    stemPath.cubicTo(w * 0.35, h * 0.65, w * 0.6, h * 0.35, w * 0.75, h * 0.05);
    canvas.drawPath(stemPath, stemPaint);

    // Draw pairs of circular/oval eucalyptus leaves along stem
    final leafData = [
      {
        'pos': Offset(w * 0.25, h * 0.80),
        'rx': w * 0.22,
        'ry': h * 0.10,
        'rot': -0.3,
      },
      {
        'pos': Offset(w * 0.40, h * 0.82),
        'rx': w * 0.20,
        'ry': h * 0.09,
        'rot': 0.4,
      },
      {
        'pos': Offset(w * 0.38, h * 0.55),
        'rx': w * 0.20,
        'ry': h * 0.09,
        'rot': -0.2,
      },
      {
        'pos': Offset(w * 0.52, h * 0.57),
        'rx': w * 0.18,
        'ry': h * 0.08,
        'rot': 0.3,
      },
      {
        'pos': Offset(w * 0.55, h * 0.32),
        'rx': w * 0.16,
        'ry': h * 0.07,
        'rot': -0.15,
      },
      {
        'pos': Offset(w * 0.68, h * 0.33),
        'rx': w * 0.15,
        'ry': h * 0.07,
        'rot': 0.25,
      },
      {
        'pos': Offset(w * 0.75, h * 0.10),
        'rx': w * 0.12,
        'ry': h * 0.06,
        'rot': 0.0,
      },
    ];

    for (int i = 0; i < leafData.length; i++) {
      final item = leafData[i];
      final pos = item['pos'] as Offset;
      final rx = item['rx'] as double;
      final ry = item['ry'] as double;
      final rot = item['rot'] as double;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      // Leaf shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(1.5, 2.5),
          width: rx * 2,
          height: ry * 2,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Leaf fill
      final fillPaint = Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [
                colors[i % colors.length],
                colors[(i + 1) % colors.length],
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: rx * 2,
                height: ry * 2,
              ),
            );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        fillPaint,
      );

      // Dewdrop highlight
      canvas.drawCircle(
        Offset(-rx * 0.35, -ry * 0.25),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.65),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EucalyptusPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// 4. Custom painter for wild grass blades (sunlit tips, layered prairie greenery)
class _WildGrassPainter extends CustomPainter {
  final List<Color> colors;

  _WildGrassPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw 5 graceful curving grass blades with varied heights and bends
    final blades = [
      {
        'base': Offset(w * 0.1, h),
        'ctrl': Offset(w * 0.05, h * 0.4),
        'tip': Offset(w * 0.3, h * 0.05),
        'width': 3.5,
      },
      {
        'base': Offset(w * 0.3, h),
        'ctrl': Offset(w * 0.45, h * 0.45),
        'tip': Offset(w * 0.6, h * 0.15),
        'width': 3.2,
      },
      {
        'base': Offset(w * 0.5, h),
        'ctrl': Offset(w * 0.35, h * 0.35),
        'tip': Offset(w * 0.15, h * 0.2),
        'width': 3.0,
      },
      {
        'base': Offset(w * 0.7, h),
        'ctrl': Offset(w * 0.85, h * 0.4),
        'tip': Offset(w * 0.95, h * 0.1),
        'width': 2.8,
      },
      {
        'base': Offset(w * 0.85, h),
        'ctrl': Offset(w * 0.75, h * 0.5),
        'tip': Offset(w * 0.65, h * 0.3),
        'width': 2.5,
      },
    ];

    for (int i = 0; i < blades.length; i++) {
      final b = blades[i];
      final base = b['base'] as Offset;
      final ctrl = b['ctrl'] as Offset;
      final tip = b['tip'] as Offset;
      final width = b['width'] as double;

      final p = Path();
      p.moveTo(base.dx - width * 0.5, base.dy);
      p.quadraticBezierTo(ctrl.dx - width * 0.2, ctrl.dy, tip.dx, tip.dy);
      p.quadraticBezierTo(
        ctrl.dx + width * 0.2,
        ctrl.dy,
        base.dx + width * 0.5,
        base.dy,
      );
      p.close();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [colors.last, colors[i % colors.length], colors.first],
        ).createShader(Rect.fromPoints(base, tip));
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WildGrassPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AMBIENT NATURE BACKDROP WRAPPER
/// Wraps any screen with organic watercolor ambient glowing light meshes
/// and subtle botanical nature elements along the perimeter.
/// ─────────────────────────────────────────────────────────────────────────────
class AmbientNatureBackdrop extends StatefulWidget {
  final Widget child;
  final bool showTopLeaf;
  final bool showBottomLeaf;
  final BotanicalLeafStyle leafStyle;
  final List<Color>? leafColors;
  final bool enableParticles;

  const AmbientNatureBackdrop({
    super.key,
    required this.child,
    this.showTopLeaf = true,
    this.showBottomLeaf = true,
    this.leafStyle = BotanicalLeafStyle.tropicalFoliage,
    this.leafColors,
    this.enableParticles = true,
  });

  @override
  State<AmbientNatureBackdrop> createState() => _AmbientNatureBackdropState();
}

class _AmbientNatureBackdropState extends State<AmbientNatureBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<Offset> _touchPoints = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerEvent(PointerEvent event) {
    if (!mounted) return;
    setState(() {
      if (_touchPoints.length > 4) {
        _touchPoints.removeAt(0);
      }
      _touchPoints.add(event.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF1D142E), // rich twilight plum/violet at top
                  Color(0xFF140D24), // deep obsidian
                  Color(0xFF0E081A), // dark midnight core
                  Color(0xFF181028), // velvet base
                ]
              : const [
                  Color(0xFFFFFDF9), // morning sunlit warmth
                  Color(0xFFFAF7F4), // soft organic pearl
                  Color(0xFFF7F3FB), // soft botanical lavender blush
                  Color(0xFFF5F2EB), // gentle natural parchment
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Sunlit Watercolor Meshes (Gold Sun top-right, Sky blue top-left, Mint bottom-left)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFFFFB300) : const Color(0xFFFFD54F))
                        .withValues(alpha: isDark ? 0.12 : 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF6366F1) : const Color(0xFF7DD3FC))
                        .withValues(alpha: isDark ? 0.10 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF00BFA5) : const Color(0xFF64FFDA))
                        .withValues(alpha: isDark ? 0.08 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Interactive Twinkling Golden Fireflies & Fairy Dust Particles
          if (widget.enableParticles)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _InteractiveNatureAuraPainter(
                        progress: _animController.value,
                        isDark: isDark,
                        recentTouch: _touchPoints.isNotEmpty
                            ? _touchPoints.last
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),

          // 3. Decorative Botanical Foliage Sprigs along perimeter with Gentle Sway
          if (widget.showTopLeaf)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final sway =
                    math.sin(_animController.value * 2 * math.pi) * 0.035;
                return Positioned(
                  top: -10,
                  right: -15,
                  child: BotanicalLeafDecoration(
                    style: widget.leafStyle,
                    width: 95,
                    height: 145,
                    rotation: -0.32 + sway,
                    opacity: isDark ? 0.30 : 0.48,
                    customColors:
                        widget.leafColors ??
                        BotanicalLeafDecoration.emeraldForest,
                  ),
                );
              },
            ),

          if (widget.showBottomLeaf)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final sway =
                    math.cos(_animController.value * 2 * math.pi) * 0.035;
                return Positioned(
                  bottom: 30,
                  left: -18,
                  child: BotanicalLeafDecoration(
                    style: BotanicalLeafStyle.wildGrass,
                    width: 85,
                    height: 120,
                    rotation: 0.22 + sway,
                    opacity: isDark ? 0.26 : 0.42,
                    customColors: BotanicalLeafDecoration.warmOlive,
                  ),
                );
              },
            ),

          // 4. Interactive Touch Listener wrapping Child Screen Content
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerEvent,
            onPointerMove: _onPointerEvent,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// INTERACTIVE NATURE AURA PAINTER
/// Drifting golden fireflies, mint dew motes, and radiant stardust touch ripples.
/// ─────────────────────────────────────────────────────────────────────────────
class _InteractiveNatureAuraPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Offset? recentTouch;

  static final List<math.Point<double>> _fireflySeeds = List.generate(
    14,
    (i) => math.Point((0.08 + (i * 0.071)) % 1.0, (0.05 + (i * 0.063)) % 1.0),
  );

  _InteractiveNatureAuraPainter({
    required this.progress,
    required this.isDark,
    this.recentTouch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * 2 * math.pi;

    // 1. Drifting fireflies & fairy dust motes
    for (int i = 0; i < _fireflySeeds.length; i++) {
      final seed = _fireflySeeds[i];
      final dx = math.sin(t + i * 1.3) * 16.0;
      final dy = math.cos(t * 0.8 + i * 1.7) * 20.0;

      final cx = (seed.x * w + dx) % w;
      final cy = (seed.y * h + dy) % h;

      // Twinkle pulsation
      final pulse = (math.sin(t * 2 + i * 2.1) + 1.0) / 2.0; // 0..1
      final alpha = (isDark ? 0.18 : 0.28) + (pulse * (isDark ? 0.25 : 0.35));
      final radius = 2.0 + (pulse * 3.5);

      final Color color = (i % 3 == 0)
          ? const Color(0xFFFFD54F) // Warm Gold
          : (i % 3 == 1)
          ? const Color(0xFF64FFDA) // Dew Mint
          : const Color(0xFFC084FC); // Luminous Lavender

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(Offset(cx, cy), radius, paint);

      // Core tiny bright spark
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.9);
      canvas.drawCircle(Offset(cx, cy), radius * 0.45, corePaint);
    }

    // 2. Interactive Touch Stardust Ripple / Aura
    if (recentTouch != null) {
      final touchPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: isDark ? 0.22 : 0.18),
            const Color(0xFFA855F7).withValues(alpha: isDark ? 0.15 : 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: recentTouch!, radius: 55));
      canvas.drawCircle(recentTouch!, 55, touchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveNatureAuraPainter oldDelegate) =>
      true;
}
