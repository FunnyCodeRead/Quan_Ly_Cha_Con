import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quan_ly_cha_con/models/chat_message.dart';
import 'package:quan_ly_cha_con/services/chat/chat_key_store.dart';
import 'package:quan_ly_cha_con/services/chat/e2ee_service.dart';

abstract class ChatRepository {
  Future<void> ensureChatExists(String chatId, List<String> participants);
  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> sendMessage(
      String chatId,
      ChatMessage msg, {
        required bool meIsPremium,
      });

  Future<int> countMessages(String chatId);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int freeLimit = 200;

  @override
  Future<void> ensureChatExists(String chatId, List<String> participants) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'securityLevel': 'free', // free | e2ee
      });
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final msgCol = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return msgCol.snapshots().asyncMap((snap) async {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final security = (chatDoc.data()?['securityLevel'] ?? 'free') as String;

      final key =
      security == 'e2ee' ? await ChatKeyStore.getKey(chatId) : null;

      return snap.docs.map((d) {
        final m = ChatMessage.fromDoc(d);

        if (security != 'e2ee') {
          return m; // free -> plaintext
        }

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
    });
  }

  @override
  Future<int> countMessages(String chatId) async {
    final agg = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .count()
        .get();

    return agg.count ?? 0; // count là int (không null)
  }

  @override
  Future<void> sendMessage(
      String chatId,
      ChatMessage msg, {
        required bool meIsPremium,
      }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final chatDoc = await chatRef.get();
    final security = (chatDoc.data()?['securityLevel'] ?? 'free') as String;

    if (meIsPremium && security != 'e2ee') {
      await chatRef.set({'securityLevel': 'e2ee'}, SetOptions(merge: true));
    }

    if (!meIsPremium && security == 'free') {
      final total = await countMessages(chatId);
      if (total >= freeLimit) {
        throw Exception(
            "Free chỉ nhắn tối đa $freeLimit tin. Nâng Premium để nhắn tiếp.");
      }
    }

    String storedText = msg.text;

    if (meIsPremium || security == 'e2ee') {
      final key = await ChatKeyStore.getOrCreateKey(chatId);
      storedText = E2EEService.encryptText(msg.text, key);
    }

    await msgRef.set({
      'senderId': msg.senderId,
      'receiverId': msg.receiverId,
      'text': storedText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': (meIsPremium || security == 'e2ee')
          ? "(tin nhắn mã hoá)"
          : msg.text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
