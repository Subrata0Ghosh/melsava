/// Membership state mirroring PostgreSQL `public.member_status` enum.
enum MembershipStatus {
  none,
  joined,
  waitlisted,
  cancelled,
  attended;

  static MembershipStatus fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'joined':
        return MembershipStatus.joined;
      case 'waitlisted':
        return MembershipStatus.waitlisted;
      case 'cancelled':
        return MembershipStatus.cancelled;
      case 'attended':
        return MembershipStatus.attended;
      default:
        return MembershipStatus.none;
    }
  }
}

/// Model representing a MELSAVA experience backed by Supabase `public.experiences`.
class ExperienceModel {
  final String id;
  final String title;
  final String description;
  final String categoryName;
  final String categoryIcon;
  final String coverImageUrl;
  final String city;
  final String venueName;
  final String venueAddress;
  final bool isOnline;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int durationMinutes;
  final int maxParticipants;
  final int currentParticipants;
  final int waitlistCount;
  final String? hostId;
  final String hostName;
  final String hostAvatar;
  final String? hostBio;
  final String? cancellationPolicy;
  final List<String> attendeeAvatars;
  final String experienceStatus;
  final MembershipStatus membershipStatus;
  final DateTime? joinedAt;
  final bool hasJoined;
  final bool isCompleted;

  const ExperienceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.categoryIcon,
    required this.coverImageUrl,
    required this.city,
    required this.venueName,
    required this.venueAddress,
    this.isOnline = false,
    required this.startsAt,
    this.endsAt,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.currentParticipants,
    this.waitlistCount = 0,
    this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.hostBio,
    this.cancellationPolicy,
    required this.attendeeAvatars,
    this.experienceStatus = 'published',
    MembershipStatus? membershipStatus,
    this.joinedAt,
    bool? hasJoined,
    bool? isCompleted,
  }) : membershipStatus =
           membershipStatus ??
           ((hasJoined ?? false)
               ? MembershipStatus.joined
               : MembershipStatus.none),
       hasJoined =
           hasJoined ??
           (membershipStatus == MembershipStatus.joined ||
               membershipStatus == MembershipStatus.attended),
       isCompleted =
           isCompleted ??
           (experienceStatus == 'completed' ||
               membershipStatus == MembershipStatus.attended);

  bool get isWaitlisted => membershipStatus == MembershipStatus.waitlisted;
  bool get isAttended => membershipStatus == MembershipStatus.attended;
  bool get isActiveMember =>
      membershipStatus == MembershipStatus.joined ||
      membershipStatus == MembershipStatus.waitlisted;
  bool get hasUnlimitedCapacity => maxParticipants <= 0;
  bool get isFull =>
      !hasUnlimitedCapacity && currentParticipants >= maxParticipants;
  int get spotsLeft => hasUnlimitedCapacity
      ? 999
      : (maxParticipants - currentParticipants).clamp(0, maxParticipants);
  bool get isPast =>
      isCompleted ||
      experienceStatus == 'completed' ||
      experienceStatus == 'cancelled' ||
      startsAt.isBefore(DateTime.now());
  bool get canJoinOrWaitlist =>
      experienceStatus == 'published' &&
      !isPast &&
      membershipStatus != MembershipStatus.joined &&
      membershipStatus != MembershipStatus.waitlisted &&
      membershipStatus != MembershipStatus.attended;

  ExperienceModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryName,
    String? categoryIcon,
    String? coverImageUrl,
    String? city,
    String? venueName,
    String? venueAddress,
    bool? isOnline,
    DateTime? startsAt,
    DateTime? endsAt,
    int? durationMinutes,
    int? maxParticipants,
    int? currentParticipants,
    int? waitlistCount,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    String? hostBio,
    String? cancellationPolicy,
    List<String>? attendeeAvatars,
    String? experienceStatus,
    MembershipStatus? membershipStatus,
    DateTime? joinedAt,
    bool? hasJoined,
    bool? isCompleted,
  }) {
    final resolvedStatus =
        membershipStatus ??
        (hasJoined != null
            ? (hasJoined ? MembershipStatus.joined : MembershipStatus.none)
            : this.membershipStatus);

    return ExperienceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      city: city ?? this.city,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      isOnline: isOnline ?? this.isOnline,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      hostBio: hostBio ?? this.hostBio,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      experienceStatus: experienceStatus ?? this.experienceStatus,
      membershipStatus: resolvedStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      hasJoined:
          hasJoined ??
          (resolvedStatus == MembershipStatus.joined ||
              resolvedStatus == MembershipStatus.attended),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
