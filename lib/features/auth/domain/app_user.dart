/// Represents an authenticated MELSAVA user
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final bool isEmailVerified;
  final bool onboardingCompleted;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.city,
    this.isEmailVerified = false,
    this.onboardingCompleted = false,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? city,
    bool? isEmailVerified,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
