import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'e2ee_key_directory_repository.dart';
import 'signal_store.dart';

class DeviceKeyManager {
  final SecureSignalProtocolStore _store;
  final E2eeKeyDirectoryRepository _directoryRepo;
  final int deviceId;

  DeviceKeyManager({
    required SecureSignalProtocolStore store,
    required E2eeKeyDirectoryRepository directoryRepo,
    this.deviceId = 1,
  })  : _store = store,
        _directoryRepo = directoryRepo;

  /// Ensures this device has an initialized Signal identity, signed prekey,
  /// and that public keys are properly published to Supabase directory.
  Future<bool> ensureDeviceInitialized() async {
    try {
      IdentityKeyPair? identityKeyPair;
      int? registrationId;

      try {
        identityKeyPair = await _store.getIdentityKeyPair();
        registrationId = await _store.getLocalRegistrationId();
      } catch (_) {
        // Keys not yet initialized
      }

      if (identityKeyPair == null || registrationId == null) {
        debugPrint('[DeviceKeyManager] Generating fresh cryptographic identity...');
        identityKeyPair = generateIdentityKeyPair();
        registrationId = generateRegistrationId(false);

        await _store.saveIdentityKeyPair(identityKeyPair);
        await _store.saveLocalRegistrationId(registrationId);

        // Generate signed prekey (ID = 1)
        final signedPreKey = generateSignedPreKey(identityKeyPair, 1);
        await _store.storeSignedPreKey(1, signedPreKey);

        // Generate batch of 50 one-time prekeys
        final preKeys = generatePreKeys(1, 50);
        final otkList = <Map<String, dynamic>>[];

        for (final pk in preKeys) {
          await _store.storePreKey(pk.id, pk);
          otkList.add({
            'key_id': pk.id,
            'public_key': base64Encode(pk.getKeyPair().publicKey.serialize()),
          });
        }

        // Register with Supabase public directory
        final regSuccess = await _directoryRepo.registerDeviceKeys(
          deviceId: deviceId,
          registrationId: registrationId,
          identityKey: base64Encode(identityKeyPair.getPublicKey().serialize()),
          signedPreKeyId: 1,
          signedPreKey: base64Encode(
            signedPreKey.getKeyPair().publicKey.serialize(),
          ),
          signedPreKeySignature: base64Encode(signedPreKey.signature),
          oneTimePrekeys: otkList,
        );

        if (regSuccess) {
          debugPrint('[DeviceKeyManager] Device cryptographic identity registered successfully.');
          return true;
        } else {
          debugPrint('[DeviceKeyManager] Failed to publish device keys to Supabase.');
          return false;
        }
      } else {
        // Check if one-time prekeys need replenishment
        await _checkAndReplenishPrekeys();
        return true;
      }
    } catch (e) {
      debugPrint('[DeviceKeyManager] Initialization error: $e');
      return false;
    }
  }

  /// Checks if one-time prekeys are running low (< 15 remaining) and replenishes them.
  Future<void> _checkAndReplenishPrekeys() async {
    try {
      final unconsumed = await _directoryRepo.getUnconsumedPrekeyCount(
        deviceId: deviceId,
      );
      if (unconsumed < 15) {
        debugPrint('[DeviceKeyManager] Replenishing one-time prekeys (currently $unconsumed remaining)...');
        final startId = DateTime.now().millisecondsSinceEpoch % 100000;
        final newPreKeys = generatePreKeys(startId, 40);
        final otkList = <Map<String, dynamic>>[];

        for (final pk in newPreKeys) {
          await _store.storePreKey(pk.id, pk);
          otkList.add({
            'key_id': pk.id,
            'public_key': base64Encode(pk.getKeyPair().publicKey.serialize()),
          });
        }

        await _directoryRepo.replenishOneTimePrekeys(
          deviceId: deviceId,
          oneTimePrekeys: otkList,
        );
        debugPrint('[DeviceKeyManager] Successfully replenished ${otkList.length} prekeys.');
      }
    } catch (e) {
      debugPrint('[DeviceKeyManager] Replenishment error: $e');
    }
  }
}
