import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/crypto/e2ee_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  final ChatLocalDataSource local;

  static const int freeLimit = 200;

  ChatRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<void> ensureChatExists(String chatId, List<String> participants) {
    return remote.ensureChatExists(chatId, participants);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final controller = StreamController<List<ChatMessage>>();

    late StreamSubscription sub;
    sub = remote.watchMessageSnapshots(chatId).listen(
          (snap) async {
        final security = await getChatSecurityLevel(chatId);
        final key = security == 'e2ee' ? await getKey(chatId) : null;

        final list = snap.docs.map((d) {
          final m = ChatMessageModel.fromDoc(d);

          if (security != 'e2ee') return m;

          if (key == null) {
            return m.copyWith(text: "🔒 Chưa có khoá để đọc");
          }

          try {
            final plain = E2EEService.decryptText(m.text, key);
            return m.copyWith(text: plain);
          } catch (_) {
            return m.copyWith(text: "⚠️ Không giải mã được");
          }
        }).toList();

        controller.add(list);
      },
      onError: (e, __) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          controller.add(const []);
          return;
        }
        controller.addError(e);
      },
    );

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<void> sendMessage(
      String chatId,
      ChatMessage msg, {
        required bool meIsPremium,
      }) async {
    final security = await getChatSecurityLevel(chatId);
    final hasPremiumParent = await chatHasPremiumParent(chatId);

    final hasPremiumAccess = meIsPremium || hasPremiumParent || security == 'e2ee';
    var effectiveSecurity = security;

    if (hasPremiumAccess && security != 'e2ee') {
      await remote.setSecurityLevel(chatId, 'e2ee');
      effectiveSecurity = 'e2ee';
    }

    if (!hasPremiumAccess && security == 'free') {
      final total = await countMessages(chatId);
      if (total >= freeLimit) {
        throw Exception(
          "Free chỉ nhắn tối đa $freeLimit tin. Nâng Premium để nhắn tiếp.",
        );
      }
    }

    String storedText = msg.text;

    if (hasPremiumAccess) {
      final key = await getOrCreateKey(chatId);
      storedText = E2EEService.encryptText(msg.text, key);
    }

    final model = ChatMessageModel(
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      text: storedText,
      timestamp: msg.timestamp,
    );

    await remote.sendRawMessage(chatId, model);

    // update meta an toàn: setSecurityLevel đã merge
    if (effectiveSecurity == 'e2ee') {
      await remote.setSecurityLevel(chatId, 'e2ee');
    }
  }

  @override
  Future<int> countMessages(String chatId) => remote.countMessages(chatId);

  @override
  Future<String> getChatSecurityLevel(String chatId) =>
      remote.getChatSecurityLevel(chatId);

  @override
  Future<bool> chatHasPremiumParent(String chatId) =>
      remote.chatHasPremiumParent(chatId);

  // ===== local key =====
  @override
  Future<String> getOrCreateKey(String chatId) => local.getOrCreateKey(chatId);

  @override
  Future<String?> getKey(String chatId) => local.getKey(chatId);

  @override
  Future<void> saveKey(String chatId, String base64Key) =>
      local.saveKey(chatId, base64Key);

  @override
  Future<void> deleteKey(String chatId) => local.deleteKey(chatId);
}
