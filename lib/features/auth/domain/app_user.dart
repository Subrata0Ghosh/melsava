/// Represents an authenticated MELSAVA user.
///
/// Sensitive PII such as exact `date_of_birth` is intentionally omitted here
/// so it can never be accidentally exposed on public screens or profile cards.
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final String? bio;
  final String? primaryIntent;
  final List<String> secondaryIntents;
  final List<String>? interests;
  final List<String> preferredActivityCategories;
  final List<String> availability;
  final int discoveryMinAge;
  final int discoveryMaxAge;
  final int discoveryMaxDistanceKm;
  final String discoveryFormat;
  final bool isEmailVerified;
  final bool ageVerified;
  final bool guidelinesAccepted;
  final bool onboardingCompleted;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.city,
    this.bio,
    this.primaryIntent,
    this.secondaryIntents = const [],
    this.interests,
    this.preferredActivityCategories = const [],
    this.availability = const [],
    this.discoveryMinAge = 21,
    this.discoveryMaxAge = 40,
    this.discoveryMaxDistanceKm = 25,
    this.discoveryFormat = 'Both',
    this.isEmailVerified = false,
    this.ageVerified = false,
    this.guidelinesAccepted = false,
    this.onboardingCompleted = false,
  });

  /// Determines the required next route based on actual verification & onboarding state.
  String get nextRequiredRoute {
    if (!isEmailVerified) return '/verify-email';
    if (!ageVerified) return '/adults-only';
    if (!onboardingCompleted) return '/profile-onboarding';
    return '/discover';
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? city,
    String? bio,
    String? primaryIntent,
    List<String>? secondaryIntents,
    List<String>? interests,
    List<String>? preferredActivityCategories,
    List<String>? availability,
    int? discoveryMinAge,
    int? discoveryMaxAge,
    int? discoveryMaxDistanceKm,
    String? discoveryFormat,
    bool? isEmailVerified,
    bool? ageVerified,
    bool? guidelinesAccepted,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      primaryIntent: primaryIntent ?? this.primaryIntent,
      secondaryIntents: secondaryIntents ?? this.secondaryIntents,
      interests: interests ?? this.interests,
      preferredActivityCategories:
          preferredActivityCategories ?? this.preferredActivityCategories,
      availability: availability ?? this.availability,
      discoveryMinAge: discoveryMinAge ?? this.discoveryMinAge,
      discoveryMaxAge: discoveryMaxAge ?? this.discoveryMaxAge,
      discoveryMaxDistanceKm:
          discoveryMaxDistanceKm ?? this.discoveryMaxDistanceKm,
      discoveryFormat: discoveryFormat ?? this.discoveryFormat,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      ageVerified: ageVerified ?? this.ageVerified,
      guidelinesAccepted: guidelinesAccepted ?? this.guidelinesAccepted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
