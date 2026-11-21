import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melsava/core/services/supabase_service.dart';
import 'package:melsava/features/reviews/domain/review_model.dart';

/// Abstract contract for verified attendee reviews.
abstract class ReviewsRepository {
  Future<void> submitReview(ReviewInput input);

  Future<List<ReviewModel>> fetchHostReviews(
    String hostId, {
    int limit = 20,
    int offset = 0,
  });

  Future<bool> checkEligibilityToReview(String experienceId);
}

/// Supabase implementation of [ReviewsRepository].
class SupabaseReviewsRepository implements ReviewsRepository {
  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  SupabaseClient _requireClient() {
    if (!_hasLiveSupabase) {
      throw Exception('Live Supabase client is not configured.');
    }
    return SupabaseService.client!;
  }

  @override
  Future<void> submitReview(ReviewInput input) async {
    final client = _requireClient();
    try {
      final res = await client.rpc(
        'submit_experience_review',
        params: input.toRpcParams(),
      );
      if (res is Map && res['success'] == false) {
        throw Exception(res['error'] ?? 'Failed to submit review');
      }
    } catch (e) {
      debugPrint('[SupabaseReviewsRepository] submitReview error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ReviewModel>> fetchHostReviews(
    String hostId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final client = _requireClient();
    try {
      final res = await client.rpc(
        'get_host_reviews',
        params: {'p_host_id': hostId, 'p_limit': limit, 'p_offset': offset},
      );

      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => ReviewModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[SupabaseReviewsRepository] fetchHostReviews error: $e');
      return const [];
    }
  }

  @override
  Future<bool> checkEligibilityToReview(String experienceId) async {
    final client = _requireClient();
    final uid = client.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      // 1. Check if user already reviewed
      final existing = await client
          .from('experience_reviews')
          .select('id')
          .eq('experience_id', experienceId)
          .eq('reviewer_id', uid)
          .maybeSingle();

      if (existing != null) return false;

      // 2. Check if user was marked 'attended'
      final member = await client
          .from('experience_members')
          .select('status')
          .eq('experience_id', experienceId)
          .eq('user_id', uid)
          .maybeSingle();

      if (member == null || member['status'] != 'attended') {
        return false;
      }

      // 3. Check if experience is completed
      final exp = await client
          .from('experiences')
          .select('status, host_id')
          .eq('id', experienceId)
          .single();

      // Cannot review own activity
      if (exp['host_id'] == uid) return false;
      if (exp['status'] != 'completed') return false;

      return true;
    } catch (e) {
      debugPrint('[SupabaseReviewsRepository] checkEligibility error: $e');
      return false;
    }
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return SupabaseReviewsRepository();
});

/// Family provider for fetching a host's verified reviews
final hostReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  hostId,
) async {
  final repo = ref.watch(reviewsRepositoryProvider);
  return repo.fetchHostReviews(hostId);
});

/// Family provider checking if the current user can review a specific experience
final canReviewExperienceProvider = FutureProvider.family<bool, String>((
  ref,
  experienceId,
) async {
  final repo = ref.watch(reviewsRepositoryProvider);
  return repo.checkEligibilityToReview(experienceId);
});
