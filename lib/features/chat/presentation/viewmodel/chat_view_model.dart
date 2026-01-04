import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo;

  StreamSubscription<List<ChatMessage>>? _sub;

  List<ChatMessage> messages = [];
  String securityLevel = 'free';

  ChatViewModel(this._repo);

  Future<void> openChat(String chatId) async {
    securityLevel = await _repo.getChatSecurityLevel(chatId);
    notifyListeners();

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

    // refresh security
    final latest = await _repo.getChatSecurityLevel(chatId);
    if (latest != securityLevel) {
      securityLevel = latest;
      notifyListeners();
    }
  }

  // key helpers
  Future<String> getOrCreateKey(String chatId) => _repo.getOrCreateKey(chatId);
  Future<String?> getKey(String chatId) => _repo.getKey(chatId);
  Future<void> saveKey(String chatId, String k) => _repo.saveKey(chatId, k);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
