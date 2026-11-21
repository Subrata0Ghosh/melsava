import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

abstract class E2eeKeyDirectoryRepository {
  Future<bool> registerDeviceKeys({
    required int deviceId,
    required int registrationId,
    required String identityKey,
    required int signedPreKeyId,
    required String signedPreKey,
    required String signedPreKeySignature,
    required List<Map<String, dynamic>> oneTimePrekeys,
  });

  Future<PreKeyBundle?> fetchUserPreKeyBundle(
    String userId, {
    int deviceId = 1,
  });

  Future<bool> replenishOneTimePrekeys({
    required int deviceId,
    required List<Map<String, dynamic>> oneTimePrekeys,
  });

  Future<int> getUnconsumedPrekeyCount({int deviceId = 1});
}

class SupabaseE2eeKeyDirectoryRepository implements E2eeKeyDirectoryRepository {
  final SupabaseClient? _client;

  SupabaseE2eeKeyDirectoryRepository([SupabaseClient? client])
      : _client = client ?? SupabaseService.client;

  @override
  Future<bool> registerDeviceKeys({
    required int deviceId,
    required int registrationId,
    required String identityKey,
    required int signedPreKeyId,
    required String signedPreKey,
    required String signedPreKeySignature,
    required List<Map<String, dynamic>> oneTimePrekeys,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      final res = await client.rpc(
        'register_device_keys',
        params: {
          'p_device_id': deviceId,
          'p_registration_id': registrationId,
          'p_identity_key': identityKey,
          'p_signed_prekey_id': signedPreKeyId,
          'p_signed_prekey': signedPreKey,
          'p_signed_prekey_signature': signedPreKeySignature,
          'p_one_time_prekeys': oneTimePrekeys,
        },
      );
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[E2eeKeyDirectoryRepo] registerDeviceKeys error: $e');
      return false;
    }
  }

  @override
  Future<PreKeyBundle?> fetchUserPreKeyBundle(
    String userId, {
    int deviceId = 1,
  }) async {
    final client = _client;
    if (client == null || userId.isEmpty) return null;

    try {
      final res = await client.rpc(
        'fetch_user_prekey_bundle',
        params: {
          'p_user_id': userId,
          'p_device_id': deviceId,
        },
      );

      if (res == null || res['success'] != true) {
        debugPrint('[E2eeKeyDirectoryRepo] fetchUserPreKeyBundle failed for $userId: ${res?['error']}');
        return null;
      }

      final regId = (res['registration_id'] as num).toInt();
      final devId = (res['device_id'] as num).toInt();
      final idKeyBytes = base64Decode(res['identity_key'] as String);
      final signedPreKeyId = (res['signed_prekey_id'] as num).toInt();
      final signedPreKeyBytes = base64Decode(res['signed_prekey'] as String);
      final sigBytes = base64Decode(res['signed_prekey_signature'] as String);

      final otkId = res['one_time_prekey_id'] != null
          ? (res['one_time_prekey_id'] as num).toInt()
          : null;
      final otkPubBytes = res['one_time_prekey'] != null
          ? base64Decode(res['one_time_prekey'] as String)
          : null;

      final preKeyBundle = PreKeyBundle(
        regId,
        devId,
        otkId,
        otkPubBytes != null ? Curve.decodePoint(otkPubBytes, 0) : null,
        signedPreKeyId,
        Curve.decodePoint(signedPreKeyBytes, 0),
        sigBytes,
        IdentityKey.fromBytes(idKeyBytes, 0),
      );

      return preKeyBundle;
    } catch (e) {
      debugPrint('[E2eeKeyDirectoryRepo] fetchUserPreKeyBundle error: $e');
      return null;
    }
  }

  @override
  Future<bool> replenishOneTimePrekeys({
    required int deviceId,
    required List<Map<String, dynamic>> oneTimePrekeys,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      final res = await client.rpc(
        'replenish_one_time_prekeys',
        params: {
          'p_device_id': deviceId,
          'p_one_time_prekeys': oneTimePrekeys,
        },
      );
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[E2eeKeyDirectoryRepo] replenishOneTimePrekeys error: $e');
      return false;
    }
  }

  @override
  Future<int> getUnconsumedPrekeyCount({int deviceId = 1}) async {
    final client = _client;
    if (client == null) return 0;

    try {
      final res = await client.rpc(
        'get_unconsumed_prekey_count',
        params: {'p_device_id': deviceId},
      );
      return (res as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('[E2eeKeyDirectoryRepo] getUnconsumedPrekeyCount error: $e');
      return 0;
    }
  }
}

final e2eeKeyDirectoryRepositoryProvider =
    Provider<E2eeKeyDirectoryRepository>((ref) {
  return SupabaseE2eeKeyDirectoryRepository();
});
