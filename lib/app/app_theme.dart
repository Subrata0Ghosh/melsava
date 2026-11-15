import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_typography.dart';

/// MELSAVA app-wide theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.warmIvory,
      colorScheme: _colorScheme,
      textTheme: AppTypography.textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppConstants.spacingMD,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.mauve,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sage,
        selectedColor: AppColors.mauve,
        labelStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingSM,
        ),
      ),
    );
  }

  // ── Color Scheme ──────────────────────────────────────────

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.mauve,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.sage,
    onPrimaryContainer: AppColors.deepPlum,
    secondary: AppColors.softCoral,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.warmIvory,
    onSecondaryContainer: AppColors.deepPlum,
    surface: AppColors.white,
    onSurface: AppColors.deepPlum,
    surfaceContainerHighest: AppColors.warmIvory,
    onSurfaceVariant: AppColors.mutedText,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
  );

  // ── AppBar ────────────────────────────────────────────────

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.warmIvory,
    foregroundColor: AppColors.deepPlum,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0.5,
  );

  // ── Card ──────────────────────────────────────────────────

  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
    ),
    margin: const EdgeInsets.all(AppConstants.spacingSM),
  );

  // ── Elevated Button ───────────────────────────────────────

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mauve,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLG,
            vertical: AppConstants.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadiusLarge),
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.white),
          minimumSize: const Size(double.infinity, 52),
        ),
      );

  // ── Outlined Button ───────────────────────────────────────

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mauve,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLG,
            vertical: AppConstants.spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadiusLarge),
          ),
          side: const BorderSide(color: AppColors.mauve, width: 1.5),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 52),
        ),
      );

  // ── Text Button ───────────────────────────────────────────

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.mauve,
      textStyle: AppTypography.labelLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMD,
        vertical: AppConstants.spacingSM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
      ),
    ),
  );

  // ── Input Decoration ──────────────────────────────────────

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          borderSide: const BorderSide(color: AppColors.mauve, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mutedText,
        ),
        labelStyle: AppTypography.labelMedium,
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
      );
}
