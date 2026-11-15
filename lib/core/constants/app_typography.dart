import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// MELSAVA typography system.
/// Headings use Manrope, body/labels use Inter.
class AppTypography {
  AppTypography._();

  // ── Heading styles (Manrope) ──────────────────────────────

  static TextStyle get displayLarge => GoogleFonts.manrope(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.deepPlum,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.deepPlum,
    letterSpacing: -0.3,
  );

  static TextStyle get displaySmall => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.deepPlum,
  );

  static TextStyle get headlineLarge => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.deepPlum,
  );

  static TextStyle get headlineMedium => GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  static TextStyle get headlineSmall => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  // ── Title styles (Manrope) ────────────────────────────────

  static TextStyle get titleLarge => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  static TextStyle get titleMedium => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  static TextStyle get titleSmall => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  // ── Body styles (Inter) ───────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.deepPlum,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.deepPlum,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
    height: 1.4,
  );

  // ── Label styles (Inter) ──────────────────────────────────

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.deepPlum,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.deepPlum,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedText,
  );

  /// Returns the complete [TextTheme] for use in ThemeData.
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
