import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text; // lưu cipherText trên Firestore
  final Timestamp timestamp;

  ChatMessage({
    this.id = '',
    required this.senderId,
    required this.receiverId,
    required this.text,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp,
  };


  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();

    // Doc rỗng
    if (raw == null) {
      return ChatMessage(
        id: doc.id,
        senderId: '',
        receiverId: '',
        text: '',
        timestamp: Timestamp.now(),
      );
    }

    // Doc bị lưu sai kiểu (String/List/...) -> báo rõ doc nào lỗi
    if (raw is! Map) {
      throw Exception(
        "Message doc ${doc.id} không phải Map. type=${raw.runtimeType}, value=$raw",
      );
    }

    final data = Map<String, dynamic>.from(raw);

    final ts = data['timestamp'];
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      timestamp: ts is Timestamp ? ts : Timestamp.now(),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    Timestamp? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
