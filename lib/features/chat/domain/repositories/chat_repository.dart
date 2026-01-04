import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<void> ensureChatExists(String chatId, List<String> participants);

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> sendMessage(
      String chatId,
      ChatMessage msg, {
        required bool meIsPremium,
      });

  Future<int> countMessages(String chatId);

  Future<String> getChatSecurityLevel(String chatId);

  Future<bool> chatHasPremiumParent(String chatId);

  // ===== local key (secure storage) =====
  Future<String> getOrCreateKey(String chatId);
  Future<String?> getKey(String chatId);
  Future<void> saveKey(String chatId, String base64Key);
  Future<void> deleteKey(String chatId);
}
