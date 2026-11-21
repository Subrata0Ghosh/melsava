import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

void main() {
  test('Signal Protocol: Alice and Bob full E2EE session & message test', () async {
    // 1. Bob generates identity, registrationId, signed prekey, and one-time prekeys
    final bobIdentityKeyPair = generateIdentityKeyPair();
    final bobRegistrationId = generateRegistrationId(false);
    final bobSignedPreKey = generateSignedPreKey(bobIdentityKeyPair, 1);
    final bobPreKeys = generatePreKeys(1, 10);

    // Setup Bob's store
    final bobStore = InMemorySignalProtocolStore(
      bobIdentityKeyPair,
      bobRegistrationId,
    );
    await bobStore.storeSignedPreKey(1, bobSignedPreKey);
    for (final pk in bobPreKeys) {
      await bobStore.storePreKey(pk.id, pk);
    }

    // 2. Alice wants to message Bob.
    // Alice downloads Bob's PreKeyBundle from the server (directory)
    final bobAddress = SignalProtocolAddress('bob', 1);
    final aliceAddress = SignalProtocolAddress('alice', 1);

    final preKeyBundle = PreKeyBundle(
      bobRegistrationId,
      1,
      bobPreKeys.first.id,
      bobPreKeys.first.getKeyPair().publicKey,
      1,
      bobSignedPreKey.getKeyPair().publicKey,
      bobSignedPreKey.signature,
      bobIdentityKeyPair.getPublicKey(),
    );

    // Setup Alice's store
    final aliceIdentityKeyPair = generateIdentityKeyPair();
    final aliceRegistrationId = generateRegistrationId(false);
    final aliceStore = InMemorySignalProtocolStore(
      aliceIdentityKeyPair,
      aliceRegistrationId,
    );

    // 3. Alice initiates session using Bob's prekey bundle
    final aliceSessionBuilder = SessionBuilder.fromSignalStore(
      aliceStore,
      bobAddress,
    );
    await aliceSessionBuilder.processPreKeyBundle(preKeyBundle);

    // 4. Alice encrypts a message for Bob
    final aliceCipher = SessionCipher.fromStore(aliceStore, bobAddress);
    final plaintext = utf8.encode('Hello Bob, this is a secret E2EE message from Alice!');
    final ciphertext = await aliceCipher.encrypt(plaintext);

    expect(ciphertext, isNotNull);
    expect(ciphertext.getType(), equals(CiphertextMessage.prekeyType));

    // 5. Bob receives Alice's PreKeySignalMessage and decrypts it
    final bobCipher = SessionCipher.fromStore(bobStore, aliceAddress);
    final decryptedBytes = await bobCipher.decrypt(
      PreKeySignalMessage(ciphertext.serialize()),
    );
    final decryptedText = utf8.decode(decryptedBytes);

    expect(decryptedText, equals('Hello Bob, this is a secret E2EE message from Alice!'));

    // 6. Bob replies to Alice (standard SignalMessage, ratcheted)
    final replyPlaintext = utf8.encode('Hey Alice! I got your secret message.');
    final replyCiphertext = await bobCipher.encrypt(replyPlaintext);

    expect(replyCiphertext.getType(), equals(CiphertextMessage.whisperType));

    // 7. Alice receives and decrypts Bob's reply
    final aliceDecryptedBytes = await aliceCipher.decryptFromSignal(
      SignalMessage.fromSerialized(replyCiphertext.serialize()),
    );
    final aliceDecryptedText = utf8.decode(aliceDecryptedBytes);

    expect(aliceDecryptedText, equals('Hey Alice! I got your secret message.'));
  });
}
