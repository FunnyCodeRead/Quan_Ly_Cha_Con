import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

class E2EEService {
  /// AES-256 key (32 bytes), base64Url
  static String generateBase64Key() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static Encrypter _encrypterFromKey(String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    final key = Key(keyBytes);
    return Encrypter(AES(key, mode: AESMode.gcm));
  }

  /// Return "iv:cipher"
  static String encryptText(String plain, String base64Key) {
    final encrypter = _encrypterFromKey(base64Key);
    final iv = IV.fromSecureRandom(12); // GCM: 12 bytes
    final encrypted = encrypter.encrypt(plain, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  static String decryptText(String bundle, String base64Key) {
    final parts = bundle.split(':');
    if (parts.length != 2) return '';
    final iv = IV.fromBase64(parts[0]);
    final cipher = Encrypted.fromBase64(parts[1]);
    final encrypter = _encrypterFromKey(base64Key);
    return encrypter.decrypt(cipher, iv: iv);
  }
}
