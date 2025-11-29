import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/services/chat/chat_key_store.dart';


Future<void> showEnterKeyDialog(
    BuildContext context, String chatId) async {
  final ctrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("Nhập khoá chat"),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          hintText: "Dán khoá do cha/mẹ cung cấp",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final key = ctrl.text.trim();
            if (key.isEmpty) return;
            await ChatKeyStore.saveKey(chatId, key);
            Navigator.pop(context);
          },
          child: const Text("Lưu"),
        ),
      ],
    ),
  );
}
