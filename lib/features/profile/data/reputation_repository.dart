import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melsava/core/services/supabase_service.dart';
import 'package:melsava/features/profile/domain/reputation_model.dart';

/// Contract for fetching host reputation and trust signals.
abstract class ReputationRepository {
  Future<HostReputationModel> fetchHostReputation(String hostId);
}

/// Supabase-backed implementation of [ReputationRepository].
class SupabaseReputationRepository implements ReputationRepository {
  bool get _hasLiveSupabase =>
      SupabaseService.isConfigured && SupabaseService.client != null;

  SupabaseClient _requireClient() {
    if (!_hasLiveSupabase) {
      throw Exception('Live Supabase client is not configured.');
    }
    return SupabaseService.client!;
  }

  @override
  Future<HostReputationModel> fetchHostReputation(String hostId) async {
    final client = _requireClient();
    try {
      final res = await client.rpc(
        'get_host_reputation',
        params: {'p_host_id': hostId},
      );

      if (res is Map) {
        return HostReputationModel.fromJson(Map<String, dynamic>.from(res));
      }
      throw Exception('Invalid reputation response format');
    } catch (e) {
      debugPrint(
        '[SupabaseReputationRepository] fetchHostReputation error: $e',
      );
      // Return safe fallback for new host rather than crashing UI
      return HostReputationModel(
        hostId: hostId,
        displayName: 'Host',
        reputationLevel: HostReputationLevel.newHost,
        isNewHost: true,
        completedHostedCount: 0,
        totalHostedCount: 0,
        attendedCirclesCount: 0,
        hostedCancellationsCount: 0,
        reviewsCount: 0,
        averageRating: null,
        hasNumericRating: false,
        hostingAttendanceRate: null,
        isIdentityVerified: false,
        isEmailConfirmed: false,
        isProfileCompleted: true,
        communityGuidelinesAccepted: true,
      );
    }
  }
}

final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  return SupabaseReputationRepository();
});

/// Family provider for fetching host reputation by hostId
final hostReputationProvider =
    FutureProvider.family<HostReputationModel, String>((ref, hostId) async {
      final repo = ref.watch(reputationRepositoryProvider);
      return repo.fetchHostReputation(hostId);
    });
