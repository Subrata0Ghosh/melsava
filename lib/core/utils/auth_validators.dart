/// Pure validation helpers for MELSAVA authentication and onboarding.
class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static String? validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(
    String? value, {
    bool requireMinLength = true,
  }) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Please enter your password';
    }
    if (requireMinLength && trimmed.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (trimmed.length > 50) {
      return 'Display name must be 50 characters or fewer';
    }
    return null;
  }

  static String? validateCity(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.length < 2) {
      return 'Please enter your city or broad area';
    }
    return null;
  }

  static String? validateBio(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.length > 500) {
      return 'Short bio must be 500 characters or fewer';
    }
    return null;
  }

  /// Calculates exact age in full years on [referenceDate] (defaults to today).
  static int calculateAge(DateTime dateOfBirth, {DateTime? referenceDate}) {
    final today = referenceDate ?? DateTime.now();
    int age = today.year - dateOfBirth.year;
    final hasHadBirthdayThisYear =
        today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);
    if (!hasHadBirthdayThisYear) {
      age--;
    }
    return age;
  }

  /// Returns true only when the user is at least 18 full years old and DOB is realistic.
  static bool isAdult(DateTime dateOfBirth, {DateTime? referenceDate}) {
    final today = referenceDate ?? DateTime.now();
    if (dateOfBirth.isAfter(today)) return false;
    final age = calculateAge(dateOfBirth, referenceDate: today);
    return age >= 18 && age <= 120;
  }

  /// Formats a [DateTime] as ISO `YYYY-MM-DD` for PostgreSQL `DATE` storage.
  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
