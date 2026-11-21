/// Model representing a verified attendee review of a completed circle.
class ReviewModel {
  final String reviewId;
  final String experienceId;
  final String experienceTitle;
  final String reviewerName;
  final String reviewerAvatar;
  final double rating;
  final bool wasAsDescribed;
  final bool wasHostRespectful;
  final bool didHostArrive;
  final bool feltSafeComfortable;
  final bool wouldJoinAgain;
  final String? feedbackText;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.experienceId,
    required this.experienceTitle,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.wasAsDescribed,
    required this.wasHostRespectful,
    required this.didHostArrive,
    required this.feltSafeComfortable,
    required this.wouldJoinAgain,
    this.feedbackText,
    required this.createdAt,
  });

  String? get reviewerAvatarUrl => reviewerAvatar;
  String? get reviewFeedback => feedbackText;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['review_id']?.toString() ?? '',
      experienceId: json['experience_id']?.toString() ?? '',
      experienceTitle: json['experience_title'] as String? ?? 'MELSAVA Circle',
      reviewerName: json['reviewer_name'] as String? ?? 'Verified Attendee',
      reviewerAvatar: json['reviewer_avatar'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      wasAsDescribed: json['was_as_described'] as bool? ?? true,
      wasHostRespectful: json['was_host_respectful'] as bool? ?? true,
      didHostArrive: json['did_host_arrive'] as bool? ?? true,
      feltSafeComfortable: json['felt_safe_comfortable'] as bool? ?? true,
      wouldJoinAgain: json['would_join_again'] as bool? ?? true,
      feedbackText:
          (json['feedback_text'] ?? json['review_feedback']) as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) =>
      ReviewModel.fromJson(map);
}

/// Payload input for submitting a review on a completed activity.
class ReviewInput {
  final String experienceId;
  final double rating;
  final bool wasAsDescribed;
  final bool wasHostRespectful;
  final bool didHostArrive;
  final bool feltSafeComfortable;
  final bool wouldJoinAgain;
  final String? feedbackText;

  const ReviewInput({
    required this.experienceId,
    required this.rating,
    this.wasAsDescribed = true,
    this.wasHostRespectful = true,
    this.didHostArrive = true,
    this.feltSafeComfortable = true,
    this.wouldJoinAgain = true,
    String? feedbackText,
    String? feedback,
  }) : feedbackText = feedbackText ?? feedback;

  String? validate() {
    if (rating < 1.0 || rating > 5.0) return 'Rating must be between 1 and 5.';
    return null;
  }

  Map<String, dynamic> toRpcParams() {
    return {
      'p_experience_id': experienceId,
      'p_rating': rating,
      'p_was_as_described': wasAsDescribed,
      'p_was_host_respectful': wasHostRespectful,
      'p_did_host_arrive': didHostArrive,
      'p_felt_safe': feltSafeComfortable,
      'p_would_join_again': wouldJoinAgain,
      'p_feedback_text': feedbackText?.trim().isEmpty == true
          ? null
          : feedbackText?.trim(),
    };
  }
}
