/// Input data for creating a new local circle/activity by an eligible member.
class CircleCreationInput {
  final String title;
  final String description;
  final String categoryId;
  final String city;
  final String area;
  final String venueName;
  final String venueAddress;
  final bool isOnline;
  final DateTime startsAt;
  final int durationMinutes;
  final int maxParticipants;
  final bool isFree;
  final double priceAmount;
  final String currency;
  final bool isRecurring;
  final String? recurrencePattern;
  final String? coverImageUrl;
  final String? cancellationPolicy;

  const CircleCreationInput({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.city,
    this.area = '',
    required this.venueName,
    this.venueAddress = '',
    this.isOnline = false,
    required this.startsAt,
    required this.durationMinutes,
    required this.maxParticipants,
    this.isFree = true,
    this.priceAmount = 0.0,
    this.currency = 'INR',
    this.isRecurring = false,
    this.recurrencePattern,
    this.coverImageUrl,
    this.cancellationPolicy,
  });

  String? validate() {
    if (title.trim().length < 5) return 'Title must be at least 5 characters.';
    if (description.trim().length < 15) {
      return 'Description must be at least 15 characters.';
    }
    if (city.trim().isEmpty) return 'City is required.';
    if (startsAt.isBefore(DateTime.now())) {
      return 'Start time must be in the future.';
    }
    if (durationMinutes < 15 || durationMinutes > 480) {
      return 'Duration must be between 15 and 480 minutes.';
    }
    if (maxParticipants < 2) return 'At least 2 participants required.';
    if (maxParticipants > 30) return 'Max participants cannot exceed 30.';
    return null;
  }

  Map<String, dynamic> toRpcParams() {
    return {
      'p_title': title.trim(),
      'p_description': description.trim(),
      'p_category_id': categoryId,
      'p_city': city.trim(),
      'p_area': area.trim(),
      'p_venue_name': venueName.trim(),
      'p_venue_address': venueAddress.trim(),
      'p_is_online': isOnline,
      'p_starts_at': startsAt.toIso8601String(),
      'p_duration_minutes': durationMinutes,
      'p_max_participants': maxParticipants,
      'p_is_free': isFree,
      'p_price_amount': priceAmount,
      'p_currency': currency,
      'p_is_recurring': isRecurring,
      'p_recurrence_pattern': recurrencePattern,
      'p_cover_image_url': coverImageUrl,
      'p_cancellation_policy': cancellationPolicy,
    };
  }
}

/// Result returned by `create_user_experience` RPC.
class CircleCreationResult {
  final bool success;
  final String? experienceId;
  final String
  moderationStatus; // 'approved', 'pending_review', 'rejected', 'removed'
  final String status; // 'published', 'draft'
  final String message;

  const CircleCreationResult({
    required this.success,
    this.experienceId,
    required this.moderationStatus,
    required this.status,
    required this.message,
  });

  bool get isPendingReview => moderationStatus == 'pending_review';
  bool get isPublished =>
      status == 'published' && moderationStatus == 'approved';

  factory CircleCreationResult.fromJson(Map<String, dynamic> json) {
    return CircleCreationResult(
      success: json['success'] as bool? ?? false,
      experienceId: json['experience_id'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
      status: json['status'] as String? ?? 'published',
      message: json['message'] as String? ?? '',
    );
  }
}
