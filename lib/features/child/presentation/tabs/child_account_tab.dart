// lib/features/child/presentation/tabs/child_account_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/core/presentation/actions/logout_action.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';


class ChildAccountTab extends StatelessWidget {
  const ChildAccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;

    final name = authVM.currentUser?.name?.trim();
    final email = authVM.currentUser?.email ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (name != null && name.isNotEmpty) ? name : 'Không xác định',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async => logoutAction(context),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}
