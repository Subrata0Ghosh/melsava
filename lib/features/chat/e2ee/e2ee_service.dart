import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'device_key_manager.dart';
import 'e2ee_key_directory_repository.dart';
import 'e2ee_payload_model.dart';
import 'signal_store.dart';

class SafetyNumberResult {
  final String formattedNumber; // 60-digit formatted in 12 groups of 5
  final String rawNumber;
  final String qrCodeData;
  final bool isVerified;
  final bool hasIdentityChanged;

  const SafetyNumberResult({
    required this.formattedNumber,
    required this.rawNumber,
    required this.qrCodeData,
    required this.isVerified,
    required this.hasIdentityChanged,
  });
}

class E2eeService {
  final SecureSignalProtocolStore _store;
  final E2eeKeyDirectoryRepository _directoryRepo;
  final DeviceKeyManager _keyManager;

  // In-memory decrypted cache to prevent redundant re-decryptions during scrolling
  final Map<String, String> _decryptedCache = {};

  bool _isInitialized = false;

  E2eeService({
    SecureSignalProtocolStore? store,
    E2eeKeyDirectoryRepository? directoryRepo,
  })  : _store = store ?? SecureSignalProtocolStore(),
        _directoryRepo =
            directoryRepo ?? SupabaseE2eeKeyDirectoryRepository(),
        _keyManager = DeviceKeyManager(
          store: store ?? SecureSignalProtocolStore(),
          directoryRepo:
              directoryRepo ?? SupabaseE2eeKeyDirectoryRepository(),
        );

  SecureSignalProtocolStore get store => _store;

  /// Ensures current device has generated identity keys and published public keys to Supabase.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    final success = await _keyManager.ensureDeviceInitialized();
    _isInitialized = success;
    return success;
  }

  /// Encrypts plaintext on the sender's device using Signal Protocol Double Ratchet.
  ///
  /// Returns a Base64-encoded E2EE JSON envelope safe for Supabase database storage.
  /// Strictly prevents plaintext from leaving the client.
  Future<String> encryptMessage({
    required String recipientUserId,
    required String plaintext,
    int recipientDeviceId = 1,
  }) async {
    await initialize();

    final address = SignalProtocolAddress(recipientUserId, recipientDeviceId);

    // Establish session via X3DH if no active session exists
    final hasSession = await _store.containsSession(address);
    if (!hasSession) {
      debugPrint('[E2eeService] No active session with $recipientUserId. Fetching PreKey bundle...');
      final bundle = await _directoryRepo.fetchUserPreKeyBundle(
        recipientUserId,
        deviceId: recipientDeviceId,
      );

      if (bundle == null) {
        throw StateError(
          'Recipient has not registered encryption keys. E2EE session cannot be established.',
        );
      }

      final builder = SessionBuilder.fromSignalStore(_store, address);
      await builder.processPreKeyBundle(bundle);
      debugPrint('[E2eeService] E2EE session built successfully with $recipientUserId.');
    }

    final cipher = SessionCipher.fromStore(_store, address);
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final ciphertext = await cipher.encrypt(plaintextBytes);

    final payload = E2eePayloadModel(
      type: ciphertext.getType(),
      ciphertextBytes: ciphertext.serialize(),
      senderDeviceId: 1,
      recipientDeviceId: recipientDeviceId,
    );

    return payload.toBase64Json();
  }

  /// Decrypts an incoming message locally on the recipient device.
  Future<String> decryptMessage({
    required String messageId,
    required String senderUserId,
    required String encryptedPayload,
    int senderDeviceId = 1,
  }) async {
    // Check in-memory cache first
    if (_decryptedCache.containsKey(messageId)) {
      return _decryptedCache[messageId]!;
    }

    await initialize();

    final address = SignalProtocolAddress(senderUserId, senderDeviceId);
    final payload = E2eePayloadModel.fromBase64Json(encryptedPayload);

    final cipher = SessionCipher.fromStore(_store, address);
    Uint8List decryptedBytes;

    if (payload.type == CiphertextMessage.prekeyType) {
      final preKeyMessage = PreKeySignalMessage(payload.ciphertextBytes);
      decryptedBytes = await cipher.decrypt(preKeyMessage);
    } else {
      final signalMessage = SignalMessage.fromSerialized(payload.ciphertextBytes);
      decryptedBytes = await cipher.decryptFromSignal(signalMessage);
    }

    final decryptedText = utf8.decode(decryptedBytes);
    _decryptedCache[messageId] = decryptedText;
    return decryptedText;
  }

  /// Calculates a 60-digit Signal/WhatsApp style Safety Number for cryptographic peer verification.
  Future<SafetyNumberResult> computeSafetyNumber({
    required String localUserId,
    required String remoteUserId,
    int deviceId = 1,
  }) async {
    await initialize();

    final remoteAddress = SignalProtocolAddress(remoteUserId, deviceId);

    final localIdentityKeyPair = await _store.getIdentityKeyPair();
    final localIdentity = localIdentityKeyPair.getPublicKey();

    var remoteIdentity = await _store.getIdentity(remoteAddress);
    if (remoteIdentity == null) {
      // If we don't have their identity stored yet, fetch their public bundle
      final bundle = await _directoryRepo.fetchUserPreKeyBundle(
        remoteUserId,
        deviceId: deviceId,
      );
      if (bundle != null) {
        remoteIdentity = bundle.getIdentityKey();
        await _store.saveIdentity(remoteAddress, remoteIdentity);
      }
    }

    if (remoteIdentity == null) {
      throw StateError('Could not obtain remote identity key for $remoteUserId');
    }

    final generator = NumericFingerprintGenerator(5200);
    final fingerprint = generator.createFor(
      0,
      Uint8List.fromList(utf8.encode(localUserId)),
      localIdentity,
      Uint8List.fromList(utf8.encode(remoteUserId)),
      remoteIdentity,
    );

    final rawDisplay = fingerprint.displayableFingerprint.getDisplayText();

    // Format raw 60-digit string into 12 groups of 5 numbers
    final buffer = StringBuffer();
    for (var i = 0; i < rawDisplay.length; i += 5) {
      if (i > 0) buffer.write(' ');
      final end = (i + 5 <= rawDisplay.length) ? i + 5 : rawDisplay.length;
      buffer.write(rawDisplay.substring(i, end));
    }
    final formatted = buffer.toString();

    final isVerified = await _store.isSafetyNumberVerified(
      remoteUserId,
      deviceId: deviceId,
    );
    final hasChanged = await _store.hasIdentityChanged(
      remoteUserId,
      deviceId: deviceId,
    );

    // QR data format: melsava-e2ee://verify?u=<remote>&fp=<hex>
    final qrData =
        'melsava-e2ee://verify?u=$remoteUserId&fp=${fingerprint.scannableFingerprint.fingerprints.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

    return SafetyNumberResult(
      formattedNumber: formatted,
      rawNumber: rawDisplay,
      qrCodeData: qrData,
      isVerified: isVerified,
      hasIdentityChanged: hasChanged,
    );
  }

  Future<bool> isSafetyNumberVerified(String remoteUserId, {int deviceId = 1}) =>
      _store.isSafetyNumberVerified(remoteUserId, deviceId: deviceId);

  Future<void> setSafetyNumberVerified(
    String remoteUserId,
    bool verified, {
    int deviceId = 1,
  }) =>
      _store.setSafetyNumberVerified(remoteUserId, verified, deviceId: deviceId);

  Future<bool> hasIdentityChanged(String remoteUserId, {int deviceId = 1}) =>
      _store.hasIdentityChanged(remoteUserId, deviceId: deviceId);

  Future<void> acknowledgeIdentityChange(
    String remoteUserId, {
    int deviceId = 1,
  }) =>
      _store.acknowledgeIdentityChange(remoteUserId, deviceId: deviceId);

  void clearDecryptedCache() => _decryptedCache.clear();
}

final e2eeServiceProvider = Provider<E2eeService>((ref) {
  final repo = ref.watch(e2eeKeyDirectoryRepositoryProvider);
  return E2eeService(directoryRepo: repo);
});
