import 'package:flutter/material.dart';

/// Glossy Golden "🔥 Trending" pill badge
///
/// Matches the high-fidelity prototype reference (golden-amber gradient,
/// top gloss highlight border, flame icon, and warm amber shadow).
class TrendingBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isDark;

  const TrendingBadge({
    super.key,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFDF70), // light gloss gold
            Color(0xFFFFA726), // warm amber
            Color(0xFFF57C00), // deep golden amber
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🔥',
            style: TextStyle(
              fontSize: fontSize + 1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 4.5),
          Text(
            'Trending',
            style: TextStyle(
              color: const Color(0xFF381A00),
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
