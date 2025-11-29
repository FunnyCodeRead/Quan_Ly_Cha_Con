// lib/ui/screens/child/tabs/child_messages_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/routes/app_routes.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class ChildMessagesTab extends StatelessWidget {
  const ChildMessagesTab({super.key});

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

    if (parent == null) {
      // chưa load xong hoặc chưa liên kết
      return const Center(child: CircularProgressIndicator());
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
