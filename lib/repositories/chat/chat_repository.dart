import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
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

  Future<String> getChatSecurityLevel(String chatId);

  Future<bool> chatHasPremiumParent(String chatId);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  static const int freeLimit = 200;

  @override
  Future<void> ensureChatExists(String chatId, List<String> participants) async {
    final chatRef = _db.collection('chats').doc(chatId);

    // Firestore rules yêu cầu đúng 2 participant cho chat 1-1.
    // Sắp xếp để client và server luôn có thứ tự nhất quán.
    final uniqueParticipants = participants.toSet().toList()..sort();
    if (uniqueParticipants.length != 2) {
      throw Exception('Cuộc chat phải gồm đúng 2 người tham gia');
    }

    try {
      await chatRef.create({
        'participants': uniqueParticipants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'securityLevel': 'free', // free | e2ee
      });
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        // Chat đã có sẵn: ghép participant theo thứ tự ổn định để phù hợp rules.
        await _mergeParticipantsIfAllowed(chatRef, uniqueParticipants);
        return;
      }

      if (e.code == 'permission-denied') {
        // Có thể chat đã tồn tại nhưng đọc bị chặn; thử merge nhẹ nếu server cho phép.
        await _mergeParticipantsIfAllowed(chatRef, uniqueParticipants, swallowPermission: true);
        return;
      }

      rethrow;
    }
  }

  Future<void> _mergeParticipantsIfAllowed(
    DocumentReference<Map<String, dynamic>> chatRef,
    List<String> participants, {
    bool swallowPermission = false,
  }) async {
    try {
      await chatRef.set({
        'participants': participants,
        'securityLevel': 'free',
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' && swallowPermission) {
        return; // Không thể sửa nhưng cũng không cần crash UI.
      }
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final msgCol = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    late StreamSubscription sub;
    final controller = StreamController<List<ChatMessage>>();

    Future<void> addMessages(QuerySnapshot snap) async {
      final security = await getChatSecurityLevel(chatId);
      final key =
          security == 'e2ee' ? await ChatKeyStore.getKey(chatId) : null;

      final list = snap.docs.map((d) {
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

      controller.add(list);
    }

    sub = msgCol.snapshots().listen(
      addMessages,
      onError: (e, __) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          controller.add(const []); // Giữ UI không crash dù bị chặn đọc
          return;
        }

        controller.addError(e);
      },
    );

    controller.onCancel = () => sub.cancel();
    return controller.stream;
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

    final security = await getChatSecurityLevel(chatId);
    final hasPremiumParent = await chatHasPremiumParent(chatId);
    final hasPremiumAccess = meIsPremium || hasPremiumParent || security == 'e2ee';

    if (hasPremiumAccess && security != 'e2ee') {
      await chatRef.set({'securityLevel': 'e2ee'}, SetOptions(merge: true));
    }

    if (!hasPremiumAccess && security == 'free') {
      final total = await countMessages(chatId);
      if (total >= freeLimit) {
        throw Exception(
            "Free chỉ nhắn tối đa $freeLimit tin. Nâng Premium để nhắn tiếp.");
      }
    }

    String storedText = msg.text;

    if (hasPremiumAccess) {
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

  @override
  Future<String> getChatSecurityLevel(String chatId) async {
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      return (chatDoc.data()?['securityLevel'] ?? 'free') as String;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'free';
      }
      rethrow;
    }
  }

  @override
  Future<bool> chatHasPremiumParent(String chatId) async {
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final data = chatDoc.data();
      if (data == null) return false;

      final participants =
          (data['participants'] as List?)?.map((e) => e.toString()).toList() ??
              const [];

      if (participants.isEmpty) return false;

      final snapshots = await Future.wait(
        participants.map((id) => _rtdb.ref('users/$id').get()),
      );

      for (final snap in snapshots) {
        if (!snap.exists) continue;
        final value = snap.value;
        if (value is! Map) continue;

        final json = Map<String, dynamic>.from(value as Map);
        final role = json['role'] as String? ?? '';
        final isPremium = json['isPremium'] as bool? ?? false;

        if (role == 'cha' && isPremium) {
          return true;
        }
      }

      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }
}
