import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;

  /// Nếu e2ee: text là "iv:cipher" (đã mã hoá)
  final String text;

  final Timestamp timestamp;

  ChatMessage({
    this.id = '',
    required this.senderId,
    required this.receiverId,
    required this.text,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

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
