import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/core/utils/chat_utils.dart';

import '../../../user/domain/entities/user.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../viewmodel/chat_view_model.dart';
import '../widgets/enter_chat_key_dialog.dart';
import 'show_chat_key_screen.dart';


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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<ChatRepository>();
      try {
        await repo.ensureChatExists(_chatId, [me, widget.child.uid]);

        final security = await repo.getChatSecurityLevel(_chatId);
        if (mounted) setState(() => _chatSecurity = security);

        if (!mounted) return;
        await context.read<ChatViewModel>().openChat(_chatId);

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

    final key = await context.read<ChatViewModel>().getKey(_chatId);

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
        title: Text(widget.child.name.isNotEmpty ? widget.child.name : widget.child.email),
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
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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

                      if (mounted && security != _chatSecurity) {
                        setState(() => _chatSecurity = security);
                      }

                      final meIsPremium =
                          hasSharedPremium || hasPremiumParent || security == 'e2ee';

                      await chatVM.send(
                        _chatId,
                        msg,
                        meIsPremium: meIsPremium,
                      );

                      if (meIsPremium && _chatSecurity != 'e2ee' && mounted) {
                        setState(() => _chatSecurity = 'e2ee');
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
