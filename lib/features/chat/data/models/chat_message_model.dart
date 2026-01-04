import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    super.id = '',
    required super.senderId,
    required super.receiverId,
    required super.text,
    super.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp,
  };

  factory ChatMessageModel.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();

    if (raw == null) {
      return ChatMessageModel(
        id: doc.id,
        senderId: '',
        receiverId: '',
        text: '',
        timestamp: Timestamp.now(),
      );
    }

    if (raw is! Map) {
      throw Exception(
        "Message doc ${doc.id} không phải Map. type=${raw.runtimeType}, value=$raw",
      );
    }

    final data = Map<String, dynamic>.from(raw);
    final ts = data['timestamp'];

    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      timestamp: ts is Timestamp ? ts : Timestamp.now(),
    );
  }
}
