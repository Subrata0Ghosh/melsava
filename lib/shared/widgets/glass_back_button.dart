import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Frosted glassmorphic circular back button for immersive full-bleed screens.
/// Features subtle specular border, ambient drop shadow, and haptic feedback.
class GlassBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  final Color? iconColor;

  const GlassBackButton({
    super.key,
    required this.onTap,
    required this.isDark,
    this.iconColor,
  });

  @override
  State<GlassBackButton> createState() => _GlassBackButtonState();
}

class _GlassBackButtonState extends State<GlassBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        widget.isDark ? const Color(0xFFF3EDFC) : const Color(0xFF1D152F);
    final color = widget.iconColor ?? defaultColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0xFFE8E2EE),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: widget.isDark ? 0.28 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: color,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
