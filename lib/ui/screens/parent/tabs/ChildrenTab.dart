// lib/ui/screens/parent/tabs/children_tab.dart
import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/models/user.dart';

class ChildrenTab extends StatelessWidget {
  final List<User> children;
  final void Function(User child) onSelectChild;

  const ChildrenTab({
    Key? key,
    required this.children,
    required this.onSelectChild,
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
            leading: const Icon(Icons.person),
            title: Text(child.name),
            subtitle: Text('Email: ${child.email}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => onSelectChild(child),
          ),
        );
      },
    );
  }
}
