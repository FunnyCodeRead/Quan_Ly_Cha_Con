// lib/ui/screens/parent/tabs/children_tab.dart
import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/user.dart';

class ChildrenTab extends StatelessWidget {
  final List<User> children;

  /// Bấm vào item (đi xem vị trí / map)
  final void Function(User child) onSelectChild;

  /// Bấm icon chat (mở chat 1-1)
  final void Function(User child) onChatChild;

  const ChildrenTab({
    Key? key,
    required this.children,
    required this.onSelectChild,
    required this.onChatChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có con nào.\nVui lòng tạo tài khoản con.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(child.name.isNotEmpty ? child.name : "Con ${index + 1}"),
            subtitle: Text('Email: ${child.email}'),

            // 👇 trailing có 2 nút: chat + mũi tên
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Chat với con',
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () => onChatChild(child),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),

            onTap: () => onSelectChild(child),
          ),
        );
      },
    );
  }
}
