import 'package:flutter/material.dart';

/// MELSAVA brand color palette and adaptive theme system.
///
/// Designed to convey elegance, warmth, and genuine human connection.
class AppColors {
  AppColors._();

  // ── Light Theme Foundation ──────────────────────────────────────────
  /// Warm Ivory — primary canvas background
  static const Color warmIvory = Color(0xFFF7F3EF);

  /// Pure White — card and surface background
  static const Color white = Color(0xFFFFFFFF);

  /// Soft cream elevated surface
  static const Color creamElevated = Color(0xFFF1EAE2);

  // ── Dark Theme Foundation ───────────────────────────────────────────
  /// Deep Obsidian — primary dark canvas background
  static const Color obsidian = Color(0xFF0E0C14);

  /// Dark Surface — card and elevated surface in dark mode
  static const Color darkSurface = Color(0xFF171320);

  /// Dark Elevated — high elevation containers, chips, modals
  static const Color darkElevated = Color(0xFF231E30);

  /// Dark Border — hairline border for dark mode cards
  static const Color darkBorder = Color(0xFF2D263D);

  // ── Brand Color Identity ───────────────────────────────────────────
  /// Deep Plum — primary typography & anchor tone
  static const Color deepPlum = Color(0xFF292332);

  /// Mauve — primary signature purple/plum accent
  static const Color mauve = Color(0xFF795B91);

  /// Luminous Mauve — vibrant tint for dark mode glow & active states
  static const Color luminousMauve = Color(0xFFA67FD6);

  /// Soft Coral — warm human connection accent & highlights
  static const Color softCoral = Color(0xFFE9A18B);

  /// Vivid Coral — high contrast connection highlight
  static const Color vividCoral = Color(0xFFFF7A60);

  /// Sage / Mint — calm harmony & success badge
  static const Color sage = Color(0xFFDCE8DF);

  /// Emerald / Mint Green — active indicator & confirmed status
  static const Color mintAccent = Color(0xFF67B99A);

  // ── Neutral Typography & Borders ───────────────────────────────────
  /// Muted Text — secondary description / timestamps
  static const Color mutedText = Color(0xFF77717A);

  /// Muted Light Text — for dark mode captions and subheaders
  static const Color darkMutedText = Color(0xFFA59EB3);

  /// Light Text Primary — crisp warm white for dark mode
  static const Color darkTextPrimary = Color(0xFFF6F4FA);

  /// Subtle light divider
  static const Color divider = Color(0xFFE0DCD8);

  /// Error & Warning
  static const Color error = Color(0xFFE54D42);
  static const Color warning = Color(0xFFF5A623);

  // ── Glassmorphic & Translucent Constants ───────────────────────────
  /// Frosted glass background for light mode
  static Color glassLight = const Color(0xFFFFFFFF).withValues(alpha: 0.72);

  /// Frosted glass border for light mode
  static Color glassBorderLight = const Color(0xFFFFFFFF).withValues(alpha: 0.55);

  /// Frosted glass background for dark mode
  static Color glassDark = const Color(0xFF151120).withValues(alpha: 0.75);

  /// Frosted glass border for dark mode
  static Color glassBorderDark = const Color(0xFFFFFFFF).withValues(alpha: 0.12);

  // ── Brand Gradients ────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [mauve, softCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1D1829), Color(0xFF14101D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassHighlightGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
