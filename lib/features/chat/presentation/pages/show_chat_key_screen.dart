import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/chat_view_model.dart';

class ShowChatKeyScreen extends StatefulWidget {
  final String chatId;
  const ShowChatKeyScreen({super.key, required this.chatId});

  @override
  State<ShowChatKeyScreen> createState() => _ShowChatKeyScreenState();
}

class _ShowChatKeyScreenState extends State<ShowChatKeyScreen> {
  String? keyValue;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final k = await context.read<ChatViewModel>().getOrCreateKey(widget.chatId);
    if (!mounted) return;
    setState(() => keyValue = k);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Khoá chat E2EE")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: keyValue == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gửi khoá này cho con (chỉ lần đầu):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SelectableText(keyValue!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text("⚠️ Không chia sẻ khoá này cho người khác.",
                style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
