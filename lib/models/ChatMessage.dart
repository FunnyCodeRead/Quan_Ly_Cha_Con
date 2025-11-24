class ChatMessage {
  final String id;
  final String sender;
  final String receiver;
  final String text;
  final int timestamp;

  ChatMessage({
    this.id = '',
    this.sender = '',
    this.receiver = '',
    this.text = '',
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'text': text,
      'timestamp': timestamp,
    };
  }

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      receiver: json['receiver'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  // Copy with method để tạo bản sao với một số thuộc tính thay đổi
  ChatMessage copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? text,
    int? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'ChatMessage(id: $id, sender: $sender, receiver: $receiver, text: $text, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatMessage &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              sender == other.sender &&
              receiver == other.receiver &&
              text == other.text &&
              timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      sender.hashCode ^
      receiver.hashCode ^
      text.hashCode ^
      timestamp.hashCode;
}