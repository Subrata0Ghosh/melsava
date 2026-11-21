import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

void main() {
  group('MELSAVA Signal Protocol E2EE Security Suite', () {
    late IdentityKeyPair aliceIdentityKeyPair;
    late int aliceRegistrationId;
    late InMemorySignalProtocolStore aliceStore;
    late SignalProtocolAddress aliceAddress;

    late IdentityKeyPair bobIdentityKeyPair;
    late int bobRegistrationId;
    late SignedPreKeyRecord bobSignedPreKey;
    late List<PreKeyRecord> bobPreKeys;
    late InMemorySignalProtocolStore bobStore;
    late SignalProtocolAddress bobAddress;

    setUp(() async {
      // ── Setup Alice ──
      aliceIdentityKeyPair = generateIdentityKeyPair();
      aliceRegistrationId = generateRegistrationId(false);
      aliceStore = InMemorySignalProtocolStore(
        aliceIdentityKeyPair,
        aliceRegistrationId,
      );
      aliceAddress = SignalProtocolAddress('alice_user_id', 1);

      // ── Setup Bob ──
      bobIdentityKeyPair = generateIdentityKeyPair();
      bobRegistrationId = generateRegistrationId(false);
      bobSignedPreKey = generateSignedPreKey(bobIdentityKeyPair, 1);
      bobPreKeys = generatePreKeys(1, 10);
      bobStore = InMemorySignalProtocolStore(
        bobIdentityKeyPair,
        bobRegistrationId,
      );
      bobAddress = SignalProtocolAddress('bob_user_id', 1);

      await bobStore.storeSignedPreKey(1, bobSignedPreKey);
      for (final pk in bobPreKeys) {
        await bobStore.storePreKey(pk.id, pk);
      }
    });

    test('1. Asynchronous X3DH Session Initiation via PreKeyBundle', () async {
      // Simulate Bob publishing bundle to directory and Alice retrieving it
      final consumedOtk = bobPreKeys.first;
      final bobBundle = PreKeyBundle(
        bobRegistrationId,
        1,
        consumedOtk.id,
        consumedOtk.getKeyPair().publicKey,
        1,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentityKeyPair.getPublicKey(),
      );

      final aliceSessionBuilder = SessionBuilder.fromSignalStore(aliceStore, bobAddress);
      await aliceSessionBuilder.processPreKeyBundle(bobBundle);

      expect(await aliceStore.containsSession(bobAddress), isTrue);
    });

    test('2. Two-Way Double Ratchet Progression with Forward Secrecy', () async {
      // Establish session
      final consumedOtk = bobPreKeys.first;
      final bobBundle = PreKeyBundle(
        bobRegistrationId,
        1,
        consumedOtk.id,
        consumedOtk.getKeyPair().publicKey,
        1,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentityKeyPair.getPublicKey(),
      );

      final aliceSessionBuilder = SessionBuilder.fromSignalStore(aliceStore, bobAddress);
      await aliceSessionBuilder.processPreKeyBundle(bobBundle);

      final aliceCipher = SessionCipher.fromStore(aliceStore, bobAddress);
      final bobCipher = SessionCipher.fromStore(bobStore, aliceAddress);

      // ── Step 1: Alice -> Bob (Initial PreKeySignalMessage) ──
      final msg1 = 'Hey Bob, excited for the hiking circle tomorrow!';
      final c1 = await aliceCipher.encrypt(utf8.encode(msg1));
      expect(c1.getType(), equals(CiphertextMessage.prekeyType));

      final decrypted1 = await bobCipher.decrypt(
        PreKeySignalMessage(c1.serialize()),
      );
      expect(utf8.decode(decrypted1), equals(msg1));

      // ── Step 2: Bob -> Alice (Ratcheted WhisperMessage) ──
      final msg2 = 'Yes Alice! I will bring water and snacks.';
      final c2 = await bobCipher.encrypt(utf8.encode(msg2));
      expect(c2.getType(), equals(CiphertextMessage.whisperType));

      final decrypted2 = await aliceCipher.decryptFromSignal(
        SignalMessage.fromSerialized(c2.serialize()),
      );
      expect(utf8.decode(decrypted2), equals(msg2));

      // ── Step 3: Alice -> Bob (Ratcheted forward again) ──
      final msg3 = 'Awesome, see you at 8:00 AM at the trailhead.';
      final c3 = await aliceCipher.encrypt(utf8.encode(msg3));
      expect(c3.getType(), equals(CiphertextMessage.whisperType));

      final decrypted3 = await bobCipher.decryptFromSignal(
        SignalMessage.fromSerialized(c3.serialize()),
      );
      expect(utf8.decode(decrypted3), equals(msg3));

      // ── Step 4: Bob -> Alice (Ratcheted forward again) ──
      final msg4 = 'Perfect, see you there! 🥾';
      final c4 = await bobCipher.encrypt(utf8.encode(msg4));
      expect(c4.getType(), equals(CiphertextMessage.whisperType));

      final decrypted4 = await aliceCipher.decryptFromSignal(
        SignalMessage.fromSerialized(c4.serialize()),
      );
      expect(utf8.decode(decrypted4), equals(msg4));
    });

    test('3. Ciphertext Tampering & Integrity Verification', () async {
      // Establish session
      final consumedOtk = bobPreKeys.first;
      final bobBundle = PreKeyBundle(
        bobRegistrationId,
        1,
        consumedOtk.id,
        consumedOtk.getKeyPair().publicKey,
        1,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentityKeyPair.getPublicKey(),
      );

      final aliceSessionBuilder = SessionBuilder.fromSignalStore(aliceStore, bobAddress);
      await aliceSessionBuilder.processPreKeyBundle(bobBundle);

      final aliceCipher = SessionCipher.fromStore(aliceStore, bobAddress);
      final bobCipher = SessionCipher.fromStore(bobStore, aliceAddress);

      final secret = 'Sensitive verification info';
      final ciphertext = await aliceCipher.encrypt(utf8.encode(secret));
      final serialized = Uint8List.fromList(ciphertext.serialize());

      // Attacker flips one byte in the ciphertext payload
      serialized[serialized.length - 2] ^= 0xFF;

      // Bob's Double Ratchet / HMAC verification must reject the tampered payload
      expect(
        () async => await bobCipher.decrypt(PreKeySignalMessage(serialized)),
        throwsA(anything),
      );
    });

    test('4. Third-Party Eavesdropper Decryption Failure', () async {
      // Establish session between Alice and Bob
      final consumedOtk = bobPreKeys.first;
      final bobBundle = PreKeyBundle(
        bobRegistrationId,
        1,
        consumedOtk.id,
        consumedOtk.getKeyPair().publicKey,
        1,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentityKeyPair.getPublicKey(),
      );

      final aliceSessionBuilder = SessionBuilder.fromSignalStore(aliceStore, bobAddress);
      await aliceSessionBuilder.processPreKeyBundle(bobBundle);

      final aliceCipher = SessionCipher.fromStore(aliceStore, bobAddress);
      final secret = 'Secret meeting point coordinate';
      final ciphertext = await aliceCipher.encrypt(utf8.encode(secret));

      // Eve (an unauthorized adversary) intercepts the ciphertext
      final eveIdentityKeyPair = generateIdentityKeyPair();
      final eveRegistrationId = generateRegistrationId(false);
      final eveSignedPreKey = generateSignedPreKey(eveIdentityKeyPair, 1);
      final evePreKeys = generatePreKeys(1, 10);
      final eveStore = InMemorySignalProtocolStore(
        eveIdentityKeyPair,
        eveRegistrationId,
      );
      await eveStore.storeSignedPreKey(1, eveSignedPreKey);
      for (final pk in evePreKeys) {
        await eveStore.storePreKey(pk.id, pk);
      }
      final eveCipher = SessionCipher.fromStore(eveStore, aliceAddress);

      // Eve cannot decrypt Alice's message intended for Bob
      var failed = false;
      try {
        await eveCipher.decrypt(
          PreKeySignalMessage(ciphertext.serialize()),
        );
      } catch (_) {
        failed = true;
      }
      expect(failed, isTrue);
    });

    test('5. Replay Attack Detection & Duplicate Message Rejection', () async {
      // Establish session
      final consumedOtk = bobPreKeys.first;
      final bobBundle = PreKeyBundle(
        bobRegistrationId,
        1,
        consumedOtk.id,
        consumedOtk.getKeyPair().publicKey,
        1,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentityKeyPair.getPublicKey(),
      );

      final aliceSessionBuilder = SessionBuilder.fromSignalStore(aliceStore, bobAddress);
      await aliceSessionBuilder.processPreKeyBundle(bobBundle);

      final aliceCipher = SessionCipher.fromStore(aliceStore, bobAddress);
      final bobCipher = SessionCipher.fromStore(bobStore, aliceAddress);

      final originalMsg = 'Transfer confirmation: Approved';
      final ciphertext = await aliceCipher.encrypt(utf8.encode(originalMsg));

      // First delivery succeeds
      final decrypted = await bobCipher.decrypt(
        PreKeySignalMessage(ciphertext.serialize()),
      );
      expect(utf8.decode(decrypted), equals(originalMsg));

      // Attacker captures and replays identical message
      var replayFailed = false;
      try {
        await bobCipher.decrypt(
          PreKeySignalMessage(ciphertext.serialize()),
        );
      } catch (e) {
        if (e is DuplicateMessageException) {
          replayFailed = true;
        }
      }
      expect(replayFailed, isTrue);
    });

    test('6. Safety Number Verification (60-digit Numeric Fingerprint & QR Matching)', () async {
      // Generate fingerprint between Alice and Bob
      final generator = NumericFingerprintGenerator(5200);
      final aliceFingerprint = generator.createFor(
        1,
        utf8.encode('alice_user_id'),
        aliceIdentityKeyPair.getPublicKey(),
        utf8.encode('bob_user_id'),
        bobIdentityKeyPair.getPublicKey(),
      );

      final bobFingerprint = generator.createFor(
        1,
        utf8.encode('bob_user_id'),
        bobIdentityKeyPair.getPublicKey(),
        utf8.encode('alice_user_id'),
        aliceIdentityKeyPair.getPublicKey(),
      );

      // Both parties must compute the exact same 60-digit fingerprint
      final aliceRaw = aliceFingerprint.displayableFingerprint.getDisplayText();
      final bobRaw = bobFingerprint.displayableFingerprint.getDisplayText();

      expect(aliceRaw, equals(bobRaw));
      expect(aliceRaw.length, equals(60));

      // Format into 12 blocks of 5 digits
      final buffer = StringBuffer();
      for (var i = 0; i < aliceRaw.length; i += 5) {
        if (i > 0) buffer.write(' ');
        final end = (i + 5 <= aliceRaw.length) ? i + 5 : aliceRaw.length;
        buffer.write(aliceRaw.substring(i, end));
      }
      final formatted = buffer.toString();
      expect(formatted.split(' ').length, equals(12));

      // QR Code scannable payload comparison via Signal's compareTo
      final aliceScannable = aliceFingerprint.scannableFingerprint;
      final bobScannable = bobFingerprint.scannableFingerprint;
      expect(aliceScannable.compareTo(bobScannable.fingerprints), isTrue);
    });

    test('7. Remote Identity Key Change Triggers Fingerprint Discrepancy', () async {
      // Normal fingerprint between Alice and Bob
      final generator = NumericFingerprintGenerator(5200);
      final originalFingerprint = generator.createFor(
        1,
        utf8.encode('alice_user_id'),
        aliceIdentityKeyPair.getPublicKey(),
        utf8.encode('bob_user_id'),
        bobIdentityKeyPair.getPublicKey(),
      );

      // Malicious attacker or untrusted new identity for Bob
      final attackerIdentity = generateIdentityKeyPair();
      final untrustedFingerprint = generator.createFor(
        1,
        utf8.encode('alice_user_id'),
        aliceIdentityKeyPair.getPublicKey(),
        utf8.encode('bob_user_id'),
        attackerIdentity.getPublicKey(),
      );

      expect(
        originalFingerprint.displayableFingerprint.getDisplayText(),
        isNot(equals(untrustedFingerprint.displayableFingerprint.getDisplayText())),
      );
    });
  });
}
