import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/models/chat_message.dart';
import 'package:quan_ly_cha_con/models/user.dart';
import 'package:quan_ly_cha_con/repositories/chat/chat_repository.dart';
import 'package:quan_ly_cha_con/services/chat/chat_key_store.dart';
import 'package:quan_ly_cha_con/ui/screens/chat/show_chat_key_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/chat/enter_chat_key_dialog.dart';
import 'package:quan_ly_cha_con/utils/chat_utils.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'package:quan_ly_cha_con/viewmodel/chat/chat_view_model.dart';

class ChatScreen extends StatefulWidget {
  final User child;
  const ChatScreen({super.key, required this.child});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  late final String _chatId;
  bool _askedKey = false;
  String _chatSecurity = 'free';

  @override
  void initState() {
    super.initState();

    final authVM = context.read<AuthViewModel>();
    final me = authVM.currentUser!.uid;
    _chatId = chatIdOf(me, widget.child.uid);

    // ✅ cực quan trọng: tạo chat xong rồi mới listen (tránh PERMISSION_DENIED)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<ChatRepository>();
      try {
        await repo.ensureChatExists(_chatId, [me, widget.child.uid]);

        final security = await repo.getChatSecurityLevel(_chatId);
        if (mounted) {
          setState(() {
            _chatSecurity = security;
          });
        }

        if (!mounted) return;
        context.read<ChatViewModel>().listenChat(_chatId);

        _checkKeyFirstTime(meRole: authVM.currentUser!.role);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tạo được cuộc chat: $e')),
        );
      }
    });
  }

  Future<void> _checkKeyFirstTime({required String meRole}) async {
    if (_askedKey) return;
    _askedKey = true;

    final key = await ChatKeyStore.getKey(_chatId);

    // Con chưa có key mà chat đã e2ee -> bắt nhập
    if (meRole == 'con' && key == null && mounted) {
      await showEnterKeyDialog(context, _chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final me = authVM.currentUser!.uid;
    final meRole = authVM.currentUser!.role;
    final hasSharedPremium = authVM.hasSharedPremium;
    final isPremiumParent = authVM.isPremiumParent;

    final chatVM = context.watch<ChatViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child.name),
        actions: [
          if (meRole == 'cha' && isPremiumParent)
            IconButton(
              icon: const Icon(Icons.vpn_key),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowChatKeyScreen(chatId: _chatId),
                  ),
                );
              },
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chatVM.messages.length,
              itemBuilder: (context, i) {
                final m = chatVM.messages[i];
                final isMe = m.senderId == me;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: const InputDecoration(
                      hintText: "Nhắn tin...",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _textCtrl.text.trim();
                    if (text.isEmpty) return;

                    final msg = ChatMessage(
                      senderId: me,
                      receiverId: widget.child.uid,
                      text: text,
                    );

                    try {
                      final repo = context.read<ChatRepository>();
                      final security = await repo.getChatSecurityLevel(_chatId);
                      final hasPremiumParent =
                          await repo.chatHasPremiumParent(_chatId);
                      final latestSecurity = security;

                      if (mounted && latestSecurity != _chatSecurity) {
                        setState(() {
                          _chatSecurity = latestSecurity;
                        });
                      }

                      final meIsPremium = hasSharedPremium ||
                          hasPremiumParent ||
                          latestSecurity == 'e2ee';

                      await chatVM.send(
                        _chatId,
                        msg,
                        meIsPremium: meIsPremium,
                      );
                      if (meIsPremium && latestSecurity != 'e2ee' && mounted) {
                        setState(() {
                          _chatSecurity = 'e2ee';
                        });
                      }
                      _textCtrl.clear();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
