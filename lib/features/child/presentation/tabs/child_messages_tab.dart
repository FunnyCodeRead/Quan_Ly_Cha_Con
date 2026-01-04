// lib/ui/screens/child/tabs/child_messages_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/app/router/app_routes.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';

class ChildMessagesTab extends StatefulWidget {
  const ChildMessagesTab({super.key});

  @override
  State<ChildMessagesTab> createState() => _ChildMessagesTabState();
}

class _ChildMessagesTabState extends State<ChildMessagesTab> {
  bool _requestedParent = false;

  @override
  void initState() {
    super.initState();

    // ✅ gọi sau frame để tránh notify during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _requestedParent) return;

      final authVM = context.read<AuthViewModel>();
      final me = authVM.currentUser;

      if (me?.role == 'con') {
        _requestedParent = true;
        await authVM.loadParentForChild();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final me = authVM.currentUser;

    if (me == null) {
      return const Center(child: Text("Chưa đăng nhập"));
    }

    if (me.role != 'con') {
      return const Center(child: Text("Tab này chỉ dành cho tài khoản con."));
    }

    final parent = authVM.parentUser;
    final isLoading = authVM.status == AuthStatus.loading && parent == null;
    final hasError =
        authVM.errorMessage.isNotEmpty && authVM.status == AuthStatus.error;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (parent == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasError
                    ? authVM.errorMessage
                    : 'Không tải được thông tin cha/mẹ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  authVM.clearError();
                  await authVM.loadParentForChild();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
            title: Text(parent.name.isEmpty ? "Cha/Mẹ" : parent.name),
            subtitle: Text(parent.email),
            trailing: const Icon(Icons.chat_bubble_outline),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: parent, // ✅ user cha/mẹ thật
              );
            },
          ),
        ),
      ],
    );
  }
}
