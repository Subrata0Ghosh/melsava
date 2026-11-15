/// Configurable brand constants for the MELSAVA app.
class AppConstants {
  AppConstants._();

  // Brand
  static const String appName = 'MELSAVA';
  static const String primaryTagline = 'Meet through moments.';
  static const String secondaryTagline = 'Less swiping. More living.';

  // Spacing (8pt grid)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double cardRadiusSmall = 16.0;
  static const double cardRadiusLarge = 22.0;
  static const double buttonRadiusSmall = 14.0;
  static const double buttonRadiusLarge = 16.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
