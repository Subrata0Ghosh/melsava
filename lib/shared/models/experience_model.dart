/// Model representing a curated MELSAVA experience
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
  final int durationMinutes;
  final int maxParticipants;
  final int currentParticipants;
  final String hostName;
  final String hostAvatar;
  final List<String> attendeeAvatars;
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
    required this.durationMinutes,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.hostName,
    required this.hostAvatar,
    required this.attendeeAvatars,
    this.hasJoined = false,
    this.isCompleted = false,
  });

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
    int? durationMinutes,
    int? maxParticipants,
    int? currentParticipants,
    String? hostName,
    String? hostAvatar,
    List<String>? attendeeAvatars,
    bool? hasJoined,
    bool? isCompleted,
  }) {
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
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      hasJoined: hasJoined ?? this.hasJoined,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
