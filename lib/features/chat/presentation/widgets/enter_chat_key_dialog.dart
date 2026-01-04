import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/chat_view_model.dart';

Future<void> showEnterKeyDialog(BuildContext context, String chatId) async {
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
            await context.read<ChatViewModel>().saveKey(chatId, key);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Lưu"),
        ),
      ],
    ),
  );
}
