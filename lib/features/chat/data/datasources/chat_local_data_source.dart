import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/crypto/e2ee_service.dart';

abstract class ChatLocalDataSource {
  Future<String> getOrCreateKey(String chatId);
  Future<void> saveKey(String chatId, String base64Key);
  Future<String?> getKey(String chatId);
  Future<void> deleteKey(String chatId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String _keyName(String chatId) => "chat_key_$chatId";

  @override
  Future<String> getOrCreateKey(String chatId) async {
    final name = _keyName(chatId);
    var key = await _storage.read(key: name);
    if (key == null) {
      key = E2EEService.generateBase64Key();
      await _storage.write(key: name, value: key);
    }
    return key;
  }

  @override
  Future<void> saveKey(String chatId, String base64Key) async {
    await _storage.write(key: _keyName(chatId), value: base64Key);
  }

  @override
  Future<String?> getKey(String chatId) async {
    return _storage.read(key: _keyName(chatId));
  }

  @override
  Future<void> deleteKey(String chatId) async {
    await _storage.delete(key: _keyName(chatId));
  }
}
