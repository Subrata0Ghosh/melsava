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
  final String? area;
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
  final bool isFree;
  final double priceAmount;
  final String currency;
  final bool isRecurring;
  final String moderationStatus;
  final String? reputationLevel;
  final bool isNewHost;

  const ExperienceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.categoryIcon,
    required this.coverImageUrl,
    required this.city,
    this.area,
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
    this.isFree = true,
    this.priceAmount = 0.0,
    this.currency = 'INR',
    this.isRecurring = false,
    this.moderationStatus = 'approved',
    this.reputationLevel,
    bool? isNewHost,
  }) : isNewHost =
           isNewHost ??
           (reputationLevel == 'new_host' || reputationLevel == null),
       membershipStatus =
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
    String? area,
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
    bool? isFree,
    double? priceAmount,
    String? currency,
    bool? isRecurring,
    String? moderationStatus,
    String? reputationLevel,
    bool? isNewHost,
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
      area: area ?? this.area,
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
      isFree: isFree ?? this.isFree,
      priceAmount: priceAmount ?? this.priceAmount,
      currency: currency ?? this.currency,
      isRecurring: isRecurring ?? this.isRecurring,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      reputationLevel: reputationLevel ?? this.reputationLevel,
      isNewHost: isNewHost ?? this.isNewHost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'coverImageUrl': coverImageUrl,
      'city': city,
      'area': area,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'isOnline': isOnline,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'waitlistCount': waitlistCount,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'hostBio': hostBio,
      'cancellationPolicy': cancellationPolicy,
      'attendeeAvatars': attendeeAvatars,
      'experienceStatus': experienceStatus,
      'membershipStatus': membershipStatus.name,
      'joinedAt': joinedAt?.toIso8601String(),
      'hasJoined': hasJoined,
      'isCompleted': isCompleted,
      'isFree': isFree,
      'priceAmount': priceAmount,
      'currency': currency,
      'isRecurring': isRecurring,
      'moderationStatus': moderationStatus,
      'reputationLevel': reputationLevel,
      'isNewHost': isNewHost,
    };
  }

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    final repLevel = json['reputationLevel'] as String?;
    return ExperienceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Community',
      categoryIcon: json['categoryIcon'] as String? ?? '✨',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String?,
      venueName: json['venueName'] as String? ?? '',
      venueAddress: json['venueAddress'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      startsAt:
          DateTime.tryParse(json['startsAt']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      maxParticipants: json['maxParticipants'] as int? ?? 0,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      waitlistCount: json['waitlistCount'] as int? ?? 0,
      hostId: json['hostId'] as String?,
      hostName: json['hostName'] as String? ?? 'Host',
      hostAvatar: json['hostAvatar'] as String? ?? '',
      hostBio: json['hostBio'] as String?,
      cancellationPolicy: json['cancellationPolicy'] as String?,
      attendeeAvatars:
          (json['attendeeAvatars'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      experienceStatus: json['experienceStatus'] as String? ?? 'published',
      membershipStatus: MembershipStatus.fromDb(
        json['membershipStatus'] as String?,
      ),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
      hasJoined: json['hasJoined'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isFree: json['isFree'] as bool? ?? true,
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      isRecurring: json['isRecurring'] as bool? ?? false,
      moderationStatus: json['moderationStatus'] as String? ?? 'approved',
      reputationLevel: repLevel,
      isNewHost:
          json['isNewHost'] as bool? ??
          (repLevel == 'new_host' || repLevel == null),
    );
  }
}
