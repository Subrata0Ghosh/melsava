import 'dart:convert';
import 'dart:typed_data';

/// Represents an encrypted envelope transmitted over the network and stored in Supabase.
///
/// Contains the protocol message type (PreKey or Ratcheted SignalMessage),
/// the ciphertext bytes, sender/recipient device IDs, and protocol version.
class E2eePayloadModel {
  final int version;
  final int type; // 3 = PreKeySignalMessage, 2 = SignalMessage (whisperType)
  final Uint8List ciphertextBytes;
  final int senderDeviceId;
  final int recipientDeviceId;
  final int? registrationId;

  const E2eePayloadModel({
    this.version = 1,
    required this.type,
    required this.ciphertextBytes,
    this.senderDeviceId = 1,
    this.recipientDeviceId = 1,
    this.registrationId,
  });

  /// Serializes the model into a Base64-encoded JSON string for safe DB storage.
  String toBase64Json() {
    final map = {
      'v': version,
      't': type,
      'c': base64Encode(ciphertextBytes),
      'sd': senderDeviceId,
      'rd': recipientDeviceId,
      if (registrationId != null) 'rid': registrationId,
    };
    final jsonStr = jsonEncode(map);
    return base64Encode(utf8.encode(jsonStr));
  }

  /// Parses a Base64-encoded JSON payload from the database.
  factory E2eePayloadModel.fromBase64Json(String raw) {
    try {
      final decodedBytes = base64Decode(raw.trim());
      final jsonStr = utf8.decode(decodedBytes);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final cipherB64 = map['c'] as String? ?? '';
      return E2eePayloadModel(
        version: (map['v'] as num?)?.toInt() ?? 1,
        type: (map['t'] as num?)?.toInt() ?? 2,
        ciphertextBytes: base64Decode(cipherB64),
        senderDeviceId: (map['sd'] as num?)?.toInt() ?? 1,
        recipientDeviceId: (map['rd'] as num?)?.toInt() ?? 1,
        registrationId: (map['rid'] as num?)?.toInt(),
      );
    } catch (e) {
      // Fallback for legacy raw base64 serialization if any
      throw FormatException('Failed to parse E2EE payload: $e');
    }
  }
}
