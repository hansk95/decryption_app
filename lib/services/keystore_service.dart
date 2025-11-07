import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyStoreService {
  KeyStoreService._private();
  static final KeyStoreService instance = KeyStoreService._private();

  static const _secureKeyName = 'keystore_master_key';
  static const _prefsBlobKey = 'keystore_blob';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Map<String, String> _inMemory = {}; // stores keys and special entries

  // late final Encrypter _encrypter;
  // late final Key _masterKey; // AES key used for encrypt/decrypt
  Encrypter? _encrypter;
  Key? _masterKey; // AES key used for encrypt/decrypt
  bool _unlocked = false;

  bool get isUnlocked => _unlocked;

  // Aufruf beim App-Start: stellt sicher, dass ein Master-Key existiert.
  Future<void> init() async {
    final existing = await _secureStorage.read(key: _secureKeyName);
    if (existing == null) {
      final rnd = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
      final base64Key = base64Encode(keyBytes);
      await _secureStorage.write(key: _secureKeyName, value: base64Key);
    }
    // MasterKey wird beim unlock geladen
  }

  // Unlock: lade Master-Key aus secure storage und entschlüssele Blob in memory
  Future<void> unlock() async {
    if (_unlocked) return;
    final base64Key = await _secureStorage.read(key: _secureKeyName);
    if (base64Key == null) throw StateError('No master key present');
    final keyBytes = base64Decode(base64Key);
    _masterKey = Key(Uint8List.fromList(keyBytes));
    _encrypter = Encrypter(AES(_masterKey!, mode: AESMode.cbc));
    // lade blob aus prefs
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(_prefsBlobKey);
    if (blob == null || blob.isEmpty) {
      // leeres keystore initialisieren
      _inMemory.clear();
      await _persist(); // legt initial verschlüsselten Blob an
    } else {
      final Map<String, dynamic> map = jsonDecode(blob);
      final ivBase64 = map['iv'] as String;
      final cipherBase64 = map['cipher'] as String;
      final iv = IV(base64Decode(ivBase64));
      final encrypted = Encrypted(base64Decode(cipherBase64));
      // _encrypter ist hier sicher gesetzt, daher null-assert
      final plain = _encrypter!.decrypt(encrypted, iv: iv);
      final decoded = jsonDecode(plain) as Map<String, dynamic>;
      _inMemory
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, v as String)));
    }
    _unlocked = true;
  }

  // Lock: clear in-memory representation
  void lock() {
    _inMemory.clear();
    _unlocked = false;
    // Master-Key und Encrypter entfernen, damit unlock später neu initialisiert werden kann
    _masterKey = null;
    _encrypter = null;
  }

  // interne Persistierung: verschlüsselt _inMemory und speichert in prefs
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final plain = jsonEncode(_inMemory);
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = IV(Uint8List.fromList(ivBytes));
    // _encrypter ist nur gesetzt, wenn unlocked == true
    final encrypted = _encrypter!.encrypt(plain, iv: iv);
    final store = jsonEncode({
      'iv': base64Encode(iv.bytes),
      'cipher': base64Encode(encrypted.bytes),
    });
    await prefs.setString(_prefsBlobKey, store);
  }

  // CRUD-Operationen für symmetrische contact-keys (prefix: contact_key:)
  Future<void> saveContactKey(String contactId, String name, [String? publicKey]) async {
    if (!_unlocked) throw StateError('Keystore locked');
    _inMemory['contact_name:$contactId'] = name;
    if (publicKey != null) {
      _inMemory['contact_pub:$contactId'] = publicKey;
    }
    await _persist();
  }

  String? getContactKey(String contactId) {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory['contact_key:$contactId'];
  }

  Future<void> deleteContact(String contactId) async {
    if (!_unlocked) throw StateError('Keystore locked');
    _inMemory.remove('contact_key:$contactId');
    _inMemory.remove('contact_pub:$contactId');
    _inMemory.remove('contact_name:$contactId');
    await _persist();
  }

  List<String> listContactIdsForKeys() {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory.keys
        .where((k) => k.startsWith('contact_key:'))
        .map((k) => k.substring('contact_key:'.length))
        .toList();
  }

  // --- own keypair storage (base64) ---
  Future<void> saveOwnKeypairBase64(String privateBase64, String publicBase64) async {
    if (!_unlocked) throw StateError('Keystore locked');
    _inMemory['own_private'] = privateBase64;
    _inMemory['own_public'] = publicBase64;
    await _persist();
  }

  String? getOwnPrivateKeyBase64() {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory['own_private'];
  }

  String? getOwnPublicKeyBase64() {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory['own_public'];
  }

  // --- contact public keys (prefix: contact_pub:) ---
  Future<void> saveContactPublicKey(String contactId, String publicBase64) async {
    if (!_unlocked) throw StateError('Keystore locked');
    _inMemory['contact_pub:$contactId'] = publicBase64;
    await _persist();
  }

  Future<void> saveContact(String id, String name, [String? publicKey]) async {
    if (!_unlocked) throw StateError('Keystore locked');
    _inMemory['contact_name:$id'] = name;
    if (publicKey != null) {
      _inMemory['contact_pub:$id'] = publicKey;
    }
    await _persist();
  }

  String? getContactPublicKey(String contactId) {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory['contact_pub:$contactId'];
  }

  String? getContactName(String contactId) {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory['contact_name:$contactId'];
  }

  List<String> listContactIdsFromKeystore() {
    if (!_unlocked) throw StateError('Keystore locked');
    return _inMemory.keys
        .where((k) => k.startsWith('contact_pub:'))
        .map((k) => k.substring('contact_pub:'.length))
        .toList();
  }

  // Optional: vollständiges Zurücksetzen
  Future<void> wipeAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsBlobKey);
    await _secureStorage.delete(key: _secureKeyName);
    lock();
  }
}