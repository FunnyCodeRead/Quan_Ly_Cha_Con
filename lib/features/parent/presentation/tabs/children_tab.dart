import 'package:flutter/material.dart';
import '../../../user/domain/entities/user.dart';

class ChildrenTab extends StatelessWidget {
  final List<User> children;
  final void Function(User child) onSelectChild;
  final void Function(User child) onChatChild;
  final VoidCallback? onCreateChild;
  final void Function(User child)? onDeleteChild;

  const ChildrenTab({
    super.key,
    required this.children,
    required this.onSelectChild,
    required this.onChatChild,
    this.onCreateChild,
    this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tạo tài khoản con mới'),
              onPressed: onCreateChild,
            ),
          ),
        ),
        Expanded(
          child: children.isEmpty
              ? const Center(
            child: Text(
              'Chưa có con nào.\nVui lòng tạo tài khoản con.',
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final title = child.name.isNotEmpty ? child.name : 'Con ${index + 1}';

              return Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.person),
                  ),
                  title: Text(title),
                  subtitle: Text('Email: ${child.email}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Chat',
                        onPressed: () => onChatChild(child),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Xóa',
                        onPressed: onDeleteChild == null ? null : () => onDeleteChild!(child),
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: cs.errorContainer,
                          foregroundColor: cs.onErrorContainer,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => onSelectChild(child),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
