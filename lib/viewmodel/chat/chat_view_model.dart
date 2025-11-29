import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/chat_message.dart';
import 'package:quan_ly_cha_con/repositories/chat/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo;

  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> messages = [];

  ChatViewModel(this._repo);

  void listenChat(String chatId) {
    _sub?.cancel();
    _sub = _repo.watchMessages(chatId).listen((list) {
      messages = list;
      notifyListeners();
    });
  }

  Future<void> send(
      String chatId,
      ChatMessage msg, {
        required bool meIsPremium,
      }) async {
    await _repo.sendMessage(chatId, msg, meIsPremium: meIsPremium);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
