/// Reference option loaded from Supabase reference tables (`interests`, `intentions`, `activity_categories`).
class OnboardingOption {
  final String? id;
  final String name;
  final String? description;
  final String? category;

  const OnboardingOption({
    this.id,
    required this.name,
    this.description,
    this.category,
  });
}

/// Bundled reference lists for the Profile Onboarding Wizard.
class OnboardingReferenceData {
  final List<OnboardingOption> interests;
  final List<OnboardingOption> intentions;
  final List<OnboardingOption> activityCategories;

  const OnboardingReferenceData({
    required this.interests,
    required this.intentions,
    required this.activityCategories,
  });
}

/// Complete profile onboarding payload submitted at the end of the wizard.
class OnboardingProfileDraft {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String city;
  final String bio;
  final List<String> interests;
  final List<String> preferredActivityCategories;
  final String primaryIntention;
  final List<String> intentions;
  final List<String> availability;
  final int discoveryMinAge;
  final int discoveryMaxAge;
  final int discoveryMaxDistanceKm;
  final String discoveryFormat;
  final bool guidelinesAccepted;

  const OnboardingProfileDraft({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.city,
    required this.bio,
    required this.interests,
    required this.preferredActivityCategories,
    required this.primaryIntention,
    required this.intentions,
    required this.availability,
    required this.discoveryMinAge,
    required this.discoveryMaxAge,
    required this.discoveryMaxDistanceKm,
    required this.discoveryFormat,
    required this.guidelinesAccepted,
  });
}

/// Explicit exception raised when a user enters a date of birth under 18.
class UnderageUserException implements Exception {
  final String message;

  const UnderageUserException([
    this.message = 'MELSAVA is strictly for adults aged 18 and older.',
  ]);

  @override
  String toString() => message;
}
