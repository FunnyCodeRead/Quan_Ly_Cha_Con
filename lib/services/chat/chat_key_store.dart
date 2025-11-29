import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'e2ee_service.dart';

class ChatKeyStore {
  static const _storage = FlutterSecureStorage();

  static String _keyName(String chatId) => "chat_key_$chatId";

  /// Cha gọi cái này lần đầu -> tạo key
  static Future<String> getOrCreateKey(String chatId) async {
    final name = _keyName(chatId);
    var key = await _storage.read(key: name);
    if (key == null) {
      key = E2EEService.generateBase64Key();
      await _storage.write(key: name, value: key);
    }
    return key;
  }

  /// Con nhập key do cha đưa -> lưu lại
  static Future<void> saveKey(String chatId, String base64Key) async {
    await _storage.write(key: _keyName(chatId), value: base64Key);
  }

  static Future<String?> getKey(String chatId) async {
    return _storage.read(key: _keyName(chatId));
  }

  static Future<void> deleteKey(String chatId) async {
    await _storage.delete(key: _keyName(chatId));
  }
}
