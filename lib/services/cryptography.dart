import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final X25519 _x25519 = X25519();
  static final AesGcm _aead = AesGcm.with256bits();
  static final HashAlgorithm _sha256 = Sha256();

  // generiert ein X25519-Keypair und gibt Base64-kodierte private+public Keys zurück
  static Future<Map<String, String>> generateX25519KeypairBase64() async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privBytes = await keyPair.extractPrivateKeyBytes();
    return {
      'private': base64Encode(privBytes),
      'public': base64Encode(publicKey.bytes),
    };
  }

  // Hilfen zum (de-)serialisieren
  static SimplePublicKey publicKeyFromBase64(String b64) {
    final bytes = base64Decode(b64);
    return SimplePublicKey(Uint8List.fromList(bytes), type: KeyPairType.x25519);
  }

  // erzeugt asynchron ein KeyPair aus privater Seed-Base64
  static Future<KeyPair> keyPairFromPrivateBase64(String b64) async {
    final seed = base64Decode(b64);
    return _x25519.newKeyPairFromSeed(Uint8List.fromList(seed));
  }

  // Ableitung: aus shared secret per SHA-256 einen 32-Byte Schlüssel erzeugen
  static Future<Uint8List> _deriveKeyFromSharedSecret(List<int> sharedSecret) async {
    final hash = await _sha256.hash(sharedSecret);
    return Uint8List.fromList(hash.bytes); // 32 bytes
  }

  // Verschlüsselt eine Nachricht für recipientPublicBase64 und liefert JSON (base64-Teile)
  // Format: {"ephemeral":"...","nonce":"...","cipher":"..."}
  static Future<String> encryptForRecipient(String recipientPublicBase64, String plainText) async {
    final ephemeral = await _x25519.newKeyPair();
    final ephPub = await ephemeral.extractPublicKey();
    final recipientPub = publicKeyFromBase64(recipientPublicBase64);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: recipientPub,
    );
    final sharedBytes = await sharedSecret.extractBytes();

    // symmetrischen Schlüssel ableiten (SHA-256)
    final symmKeyBytes = await _deriveKeyFromSharedSecret(sharedBytes);

    final nonce = _aead.newNonce();
    final secretKey = SecretKey(symmKeyBytes);
    final secretBox = await _aead.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload = {
      'ephemeral': base64Encode(ephPub.bytes),
      'nonce': base64Encode(secretBox.nonce),
      'cipher': base64Encode(secretBox.cipherText + secretBox.mac.bytes),
    };
    return jsonEncode(payload);
  }

  // Entschlüsselt eine Payload (oben) mit dem eigenen privateKey (base64)
  static Future<String> decryptWithPrivate(String privateKeyBase64, String payloadJson) async {
    final data = jsonDecode(payloadJson) as Map<String, dynamic>;
    final ephB64 = data['ephemeral'] as String;
    final nonceB64 = data['nonce'] as String;
    final cipherB64 = data['cipher'] as String;

    final ephPub = publicKeyFromBase64(ephB64);
    final nonce = base64Decode(nonceB64);
    final cipherAndTag = base64Decode(cipherB64);

    final macLength = 16; // AES-GCM tag length
    if (cipherAndTag.length < macLength) {
      throw ArgumentError('Invalid cipher payload');
    }
    final cipherText = cipherAndTag.sublist(0, cipherAndTag.length - macLength);
    final macBytes = cipherAndTag.sublist(cipherAndTag.length - macLength);

    final myKeyPair = await keyPairFromPrivateBase64(privateKeyBase64);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: ephPub,
    );
    final sharedBytes = await sharedSecret.extractBytes();

    final symmKeyBytes = await _deriveKeyFromSharedSecret(sharedBytes);

    final secretKey = SecretKey(symmKeyBytes);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(Uint8List.fromList(macBytes)),
    );

    final decrypted = await _aead.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }
}