/// Host reputation levels calculated by the backend.
enum HostReputationLevel {
  newHost,
  activeHost,
  reliableHost,
  trustedHost;

  static HostReputationLevel fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'trusted_host':
        return HostReputationLevel.trustedHost;
      case 'reliable_host':
        return HostReputationLevel.reliableHost;
      case 'active_host':
        return HostReputationLevel.activeHost;
      case 'new_host':
      default:
        return HostReputationLevel.newHost;
    }
  }

  String get displayName {
    switch (this) {
      case HostReputationLevel.trustedHost:
        return 'Trusted Host';
      case HostReputationLevel.reliableHost:
        return 'Reliable Host';
      case HostReputationLevel.activeHost:
        return 'Active Host';
      case HostReputationLevel.newHost:
        return 'New Host';
    }
  }

  String get description {
    switch (this) {
      case HostReputationLevel.trustedHost:
        return 'Consistently delivers outstanding, verified community circles.';
      case HostReputationLevel.reliableHost:
        return 'Proven track record of high attendance and positive feedback.';
      case HostReputationLevel.activeHost:
        return 'Has successfully hosted and completed local activities.';
      case HostReputationLevel.newHost:
        return 'Welcoming new organizer — building their hosting reputation.';
    }
  }
}

/// Verified host trust and reputation details returned by `get_host_reputation` RPC.
class HostReputationModel {
  final String hostId;
  final String displayName;
  final HostReputationLevel reputationLevel;
  final bool isNewHost;
  final int completedHostedCount;
  final int totalHostedCount;
  final int attendedCirclesCount;
  final int hostedCancellationsCount;
  final int reviewsCount;
  final double? averageRating;
  final bool hasNumericRating;
  final double? hostingAttendanceRate;
  final bool isIdentityVerified;
  final bool isEmailConfirmed;
  final bool isProfileCompleted;
  final bool communityGuidelinesAccepted;
  final DateTime? memberSince;

  const HostReputationModel({
    String? hostId,
    String? userId,
    this.displayName = 'Host',
    HostReputationLevel? reputationLevel,
    HostReputationLevel? level,
    required this.isNewHost,
    required this.completedHostedCount,
    this.totalHostedCount = 0,
    this.attendedCirclesCount = 0,
    this.hostedCancellationsCount = 0,
    int? reviewsCount,
    int? reviewCount,
    this.averageRating,
    bool? hasNumericRating,
    this.hostingAttendanceRate,
    double? positiveRatingsPercentage,
    this.isIdentityVerified = false,
    this.isEmailConfirmed = false,
    this.isProfileCompleted = false,
    this.communityGuidelinesAccepted = true,
    bool? activityCreationRestricted,
    this.memberSince,
  }) : hostId = hostId ?? userId ?? '',
       reputationLevel =
           reputationLevel ?? level ?? HostReputationLevel.newHost,
       reviewsCount = reviewsCount ?? reviewCount ?? 0,
       hasNumericRating =
           hasNumericRating ??
           ((reviewsCount ?? reviewCount ?? 0) >= 5 && averageRating != null);

  /// True if host should show "Not yet rated" (fewer than 5 verified reviews).
  bool get showsNotYetRated =>
      !hasNumericRating || averageRating == null || reviewsCount < 5;

  HostReputationLevel get level => reputationLevel;
  String get levelDisplayName => reputationLevel.displayName;
  String get ratingDisplay => showsNotYetRated
      ? 'Not yet rated'
      : '${averageRating!.toStringAsFixed(1)} ★';

  factory HostReputationModel.fromMap(Map<String, dynamic> map) =>
      HostReputationModel.fromJson(map);

  factory HostReputationModel.fromJson(Map<String, dynamic> json) {
    final revCount =
        (json['reviews_count'] ?? json['review_count'] as num?)?.toInt() ?? 0;
    final avgRat = (json['average_rating'] as num?)?.toDouble();
    return HostReputationModel(
      hostId: json['host_id']?.toString() ?? json['user_id']?.toString() ?? '',
      displayName: json['display_name'] as String? ?? 'Host',
      reputationLevel: HostReputationLevel.fromDb(
        json['reputation_level'] as String?,
      ),
      isNewHost:
          json['is_new_host'] as bool? ?? (json['completed_hosted_count'] == 0),
      completedHostedCount:
          (json['completed_hosted_count'] as num?)?.toInt() ?? 0,
      totalHostedCount: (json['total_hosted_count'] as num?)?.toInt() ?? 0,
      attendedCirclesCount:
          (json['attended_circles_count'] as num?)?.toInt() ?? 0,
      hostedCancellationsCount:
          (json['hosted_cancellations_count'] as num?)?.toInt() ?? 0,
      reviewsCount: revCount,
      averageRating: avgRat,
      hasNumericRating:
          json['has_numeric_rating'] as bool? ??
          (revCount >= 5 && avgRat != null),
      hostingAttendanceRate: (json['hosting_attendance_rate'] as num?)
          ?.toDouble(),
      isIdentityVerified: json['is_identity_verified'] as bool? ?? false,
      isEmailConfirmed: json['is_email_confirmed'] as bool? ?? false,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
      communityGuidelinesAccepted:
          json['community_guidelines_accepted'] as bool? ?? true,
      memberSince: DateTime.tryParse(json['member_since']?.toString() ?? ''),
    );
  }
}
