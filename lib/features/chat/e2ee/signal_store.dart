import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

/// Secure, hardware-backed persistent store for Signal Protocol.
///
/// Backed by [FlutterSecureStorage] (Android Keystore / iOS Keychain)
/// with an active in-memory cache for high-throughput, low-latency encryption.
class SecureSignalProtocolStore implements SignalProtocolStore {
  final FlutterSecureStorage _storage;
  final String _namespace;

  // In-memory caches for fast cryptographic ratcheting & session lookups
  IdentityKeyPair? _identityKeyPairCache;
  int? _registrationIdCache;
  final Map<int, PreKeyRecord> _preKeyCache = {};
  final Map<int, SignedPreKeyRecord> _signedPreKeyCache = {};
  final Map<String, SessionRecord> _sessionCache = {};
  final Map<String, IdentityKey> _trustedIdentitiesCache = {};
  final Map<String, bool> _identityChangedCache = {};
  final Map<String, bool> _safetyNumberVerifiedCache = {};

  SecureSignalProtocolStore({
    FlutterSecureStorage? storage,
    String namespace = 'melsava_e2ee',
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _namespace = namespace;

  String _key(String suffix) => '${_namespace}_$suffix';

  // --------------------------------------------------------------------------
  // IdentityKeyStore Implementation
  // --------------------------------------------------------------------------

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async {
    if (_identityKeyPairCache != null) return _identityKeyPairCache!;
    final raw = await _storage.read(key: _key('identity_key_pair'));
    if (raw == null) {
      throw StateError('Identity key pair not yet initialized in secure storage');
    }
    final bytes = base64Decode(raw);
    _identityKeyPairCache = IdentityKeyPair.fromSerialized(bytes);
    return _identityKeyPairCache!;
  }

  Future<void> saveIdentityKeyPair(IdentityKeyPair pair) async {
    _identityKeyPairCache = pair;
    final b64 = base64Encode(pair.serialize());
    await _storage.write(key: _key('identity_key_pair'), value: b64);
  }

  @override
  Future<int> getLocalRegistrationId() async {
    if (_registrationIdCache != null) return _registrationIdCache!;
    final raw = await _storage.read(key: _key('registration_id'));
    if (raw == null) {
      throw StateError('Registration ID not yet initialized in secure storage');
    }
    _registrationIdCache = int.parse(raw);
    return _registrationIdCache!;
  }

  Future<void> saveLocalRegistrationId(int regId) async {
    _registrationIdCache = regId;
    await _storage.write(key: _key('registration_id'), value: regId.toString());
  }

  @override
  Future<bool> saveIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
  ) async {
    if (identityKey == null) return false;
    final addrKey = address.toString();
    final existing = await getIdentity(address);

    if (existing == null) {
      _trustedIdentitiesCache[addrKey] = identityKey;
      await _storage.write(
        key: _key('identity_$addrKey'),
        value: base64Encode(identityKey.serialize()),
      );
      return false; // Not a replacement, new contact
    }

    if (existing != identityKey) {
      // Security warning: Remote identity key has changed!
      debugPrint('[SecureSignalStore] WARNING: Identity key changed for $addrKey!');
      _identityChangedCache[addrKey] = true;
      _trustedIdentitiesCache[addrKey] = identityKey;
      await _storage.write(
        key: _key('identity_$addrKey'),
        value: base64Encode(identityKey.serialize()),
      );
      await _storage.write(key: _key('identity_changed_$addrKey'), value: 'true');
      // Invalidate previous safety number verification on key change
      _safetyNumberVerifiedCache[addrKey] = false;
      await _storage.delete(key: _key('verified_$addrKey'));
      return true; // Key was replaced
    }

    return false;
  }

  @override
  Future<bool> isTrustedIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
    Direction direction,
  ) async {
    if (identityKey == null) return false;
    final trusted = await getIdentity(address);
    if (trusted == null) {
      // Trust on first use (TOFU)
      return true;
    }
    return trusted == identityKey;
  }

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    final addrKey = address.toString();
    if (_trustedIdentitiesCache.containsKey(addrKey)) {
      return _trustedIdentitiesCache[addrKey];
    }
    final raw = await _storage.read(key: _key('identity_$addrKey'));
    if (raw == null) return null;
    final key = IdentityKey.fromBytes(base64Decode(raw), 0);
    _trustedIdentitiesCache[addrKey] = key;
    return key;
  }

  // Safety Number & Identity Change Helpers
  Future<bool> hasIdentityChanged(String userId, {int deviceId = 1}) async {
    final addrKey = SignalProtocolAddress(userId, deviceId).toString();
    if (_identityChangedCache.containsKey(addrKey)) {
      return _identityChangedCache[addrKey]!;
    }
    final raw = await _storage.read(key: _key('identity_changed_$addrKey'));
    final val = raw == 'true';
    _identityChangedCache[addrKey] = val;
    return val;
  }

  Future<void> acknowledgeIdentityChange(String userId, {int deviceId = 1}) async {
    final addrKey = SignalProtocolAddress(userId, deviceId).toString();
    _identityChangedCache[addrKey] = false;
    await _storage.delete(key: _key('identity_changed_$addrKey'));
  }

  Future<bool> isSafetyNumberVerified(String userId, {int deviceId = 1}) async {
    final addrKey = SignalProtocolAddress(userId, deviceId).toString();
    if (_safetyNumberVerifiedCache.containsKey(addrKey)) {
      return _safetyNumberVerifiedCache[addrKey]!;
    }
    final raw = await _storage.read(key: _key('verified_$addrKey'));
    final val = raw == 'true';
    _safetyNumberVerifiedCache[addrKey] = val;
    return val;
  }

  Future<void> setSafetyNumberVerified(
    String userId,
    bool verified, {
    int deviceId = 1,
  }) async {
    final addrKey = SignalProtocolAddress(userId, deviceId).toString();
    _safetyNumberVerifiedCache[addrKey] = verified;
    if (verified) {
      await _storage.write(key: _key('verified_$addrKey'), value: 'true');
    } else {
      await _storage.delete(key: _key('verified_$addrKey'));
    }
  }

  // --------------------------------------------------------------------------
  // PreKeyStore Implementation
  // --------------------------------------------------------------------------

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    if (_preKeyCache.containsKey(preKeyId)) {
      return _preKeyCache[preKeyId]!;
    }
    final raw = await _storage.read(key: _key('prekey_$preKeyId'));
    if (raw == null) {
      throw InvalidKeyIdException('No such prekey: $preKeyId');
    }
    final record = PreKeyRecord.fromBuffer(base64Decode(raw));
    _preKeyCache[preKeyId] = record;
    return record;
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    _preKeyCache[preKeyId] = record;
    await _storage.write(
      key: _key('prekey_$preKeyId'),
      value: base64Encode(record.serialize()),
    );
  }

  @override
  Future<bool> containsPreKey(int preKeyId) async {
    if (_preKeyCache.containsKey(preKeyId)) return true;
    final raw = await _storage.read(key: _key('prekey_$preKeyId'));
    return raw != null;
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    _preKeyCache.remove(preKeyId);
    await _storage.delete(key: _key('prekey_$preKeyId'));
  }

  // --------------------------------------------------------------------------
  // SignedPreKeyStore Implementation
  // --------------------------------------------------------------------------

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    if (_signedPreKeyCache.containsKey(signedPreKeyId)) {
      return _signedPreKeyCache[signedPreKeyId]!;
    }
    final raw = await _storage.read(key: _key('signed_prekey_$signedPreKeyId'));
    if (raw == null) {
      throw InvalidKeyIdException('No such signed prekey: $signedPreKeyId');
    }
    final record = SignedPreKeyRecord.fromSerialized(base64Decode(raw));
    _signedPreKeyCache[signedPreKeyId] = record;
    return record;
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final allKeys = await _storage.readAll();
    final prefix = _key('signed_prekey_');
    final records = <SignedPreKeyRecord>[];
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(prefix)) {
        try {
          records.add(SignedPreKeyRecord.fromSerialized(base64Decode(entry.value)));
        } catch (_) {}
      }
    }
    return records;
  }

  @override
  Future<void> storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    _signedPreKeyCache[signedPreKeyId] = record;
    await _storage.write(
      key: _key('signed_prekey_$signedPreKeyId'),
      value: base64Encode(record.serialize()),
    );
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    if (_signedPreKeyCache.containsKey(signedPreKeyId)) return true;
    final raw = await _storage.read(key: _key('signed_prekey_$signedPreKeyId'));
    return raw != null;
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    _signedPreKeyCache.remove(signedPreKeyId);
    await _storage.delete(key: _key('signed_prekey_$signedPreKeyId'));
  }

  // --------------------------------------------------------------------------
  // SessionStore Implementation
  // --------------------------------------------------------------------------

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    final addrKey = address.toString();
    if (_sessionCache.containsKey(addrKey)) {
      return _sessionCache[addrKey]!;
    }
    final raw = await _storage.read(key: _key('session_$addrKey'));
    if (raw == null) {
      return SessionRecord();
    }
    final record = SessionRecord.fromSerialized(base64Decode(raw));
    _sessionCache[addrKey] = record;
    return record;
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    final all = await _storage.readAll();
    final prefix = _key('session_$name::');
    final deviceIds = <int>[];
    for (final key in all.keys) {
      if (key.startsWith(prefix)) {
        final sub = key.substring(prefix.length);
        final id = int.tryParse(sub);
        if (id != null) deviceIds.add(id);
      }
    }
    return deviceIds;
  }

  @override
  Future<void> storeSession(
    SignalProtocolAddress address,
    SessionRecord record,
  ) async {
    final addrKey = address.toString();
    _sessionCache[addrKey] = record;
    await _storage.write(
      key: _key('session_$addrKey'),
      value: base64Encode(record.serialize()),
    );
  }

  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    final addrKey = address.toString();
    if (_sessionCache.containsKey(addrKey)) return true;
    final raw = await _storage.read(key: _key('session_$addrKey'));
    return raw != null;
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    final addrKey = address.toString();
    _sessionCache.remove(addrKey);
    await _storage.delete(key: _key('session_$addrKey'));
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    final all = await _storage.readAll();
    final prefix = _key('session_$name::');
    for (final k in all.keys) {
      if (k.startsWith(prefix)) {
        await _storage.delete(key: k);
      }
    }
    _sessionCache.removeWhere((k, _) => k.startsWith('$name::'));
  }

  // Clear all local state (e.g. on logout/account reset)
  Future<void> clearAll() async {
    _identityKeyPairCache = null;
    _registrationIdCache = null;
    _preKeyCache.clear();
    _signedPreKeyCache.clear();
    _sessionCache.clear();
    _trustedIdentitiesCache.clear();
    _identityChangedCache.clear();
    _safetyNumberVerifiedCache.clear();
    await _storage.deleteAll();
  }
}
