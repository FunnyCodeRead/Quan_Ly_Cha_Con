import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<void> ensureChatExists(String chatId, List<String> participants);

  Stream<QuerySnapshot> watchMessageSnapshots(String chatId);

  Future<void> sendRawMessage(String chatId, ChatMessageModel model);

  Future<int> countMessages(String chatId);

  Future<String> getChatSecurityLevel(String chatId);

  Future<void> setSecurityLevel(String chatId, String level);

  Future<bool> chatHasPremiumParent(String chatId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore db;
  final FirebaseDatabase rtdb;

  ChatRemoteDataSourceImpl({
    FirebaseFirestore? db,
    FirebaseDatabase? rtdb,
  })  : db = db ?? FirebaseFirestore.instance,
        rtdb = rtdb ?? FirebaseDatabase.instance;

  @override
  Future<void> ensureChatExists(String chatId, List<String> participants) async {
    final chatRef = db.collection('chats').doc(chatId);

    final uniqueParticipants = participants.toSet().toList()..sort();
    if (uniqueParticipants.length != 2) {
      throw Exception('Cuộc chat phải gồm đúng 2 người tham gia');
    }

    try {
      final existing = await chatRef.get();
      if (existing.exists) {
        final data = existing.data();
        final existingParticipants =
        (data?['participants'] as List?)?.map((e) => e.toString()).toList();

        if (existingParticipants != null &&
            (existingParticipants.length != uniqueParticipants.length ||
                !Set.of(existingParticipants)
                    .containsAll(uniqueParticipants))) {
          throw Exception(
              'Không thể tham gia cuộc chat vì danh sách participant không khớp');
        }
        return;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // đọc không được -> thử tạo
      } else {
        rethrow;
      }
    }

    try {
      await chatRef.set({
        'participants': uniqueParticipants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'securityLevel': 'free',
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Không có quyền tạo cuộc chat (permission-denied)');
      }
      if (e.code == 'already-exists') return;
      rethrow;
    }
  }

  @override
  Stream<QuerySnapshot> watchMessageSnapshots(String chatId) {
    return db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  Future<void> sendRawMessage(String chatId, ChatMessageModel model) async {
    final chatRef = db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    await msgRef.set({
      'senderId': model.senderId,
      'receiverId': model.receiverId,
      'text': model.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': model.text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<int> countMessages(String chatId) async {
    final agg = await db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .count()
        .get();

    return agg.count ?? 0;
  }

  @override
  Future<String> getChatSecurityLevel(String chatId) async {
    try {
      final chatDoc = await db.collection('chats').doc(chatId).get();
      return (chatDoc.data()?['securityLevel'] ?? 'free') as String;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return 'free';
      rethrow;
    }
  }

  @override
  Future<void> setSecurityLevel(String chatId, String level) async {
    final chatRef = db.collection('chats').doc(chatId);
    await chatRef.set({'securityLevel': level}, SetOptions(merge: true));
  }

  @override
  Future<bool> chatHasPremiumParent(String chatId) async {
    try {
      final chatDoc = await db.collection('chats').doc(chatId).get();
      final data = chatDoc.data();
      if (data == null) return false;

      final participants =
          (data['participants'] as List?)?.map((e) => e.toString()).toList() ??
              const [];

      if (participants.isEmpty) return false;

      final snaps = await Future.wait(
        participants.map((id) => rtdb.ref('users/$id').get()),
      );

      for (final snap in snaps) {
        if (!snap.exists) continue;
        final value = snap.value;
        if (value is! Map) continue;

        final json = Map<String, dynamic>.from(value as Map);
        final role = json['role'] as String? ?? '';
        final isPremium = json['isPremium'] as bool? ?? false;

        if (role == 'cha' && isPremium) return true;
      }

      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }
}
