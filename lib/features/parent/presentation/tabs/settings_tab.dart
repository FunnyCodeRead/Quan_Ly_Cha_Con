import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/app/router/app_routes.dart';
import 'package:quan_ly_cha_con/core/presentation/actions/logout_action.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';


class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool confirmUploads = true;

  Future<void> _confirmAndLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Đăng xuất")),
        ],
      ),
    );

    if (ok == true) {
      await logoutAction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isParent = authVM.isParent;
    final isPremium = authVM.isPremiumParent;

    return ListView(
      children: [
        const SizedBox(height: 8),

        SwitchListTile(
          value: confirmUploads,
          onChanged: (v) => setState(() => confirmUploads = v),
          title: const Text("Confirm Uploads"),
          secondary: const Icon(Icons.check_circle_outline),
        ),

        const Divider(),

        if (isParent) ...[
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(isPremium ? "Premium: Đang hoạt động" : "Nâng cấp Premium"),
            subtitle: const Text("Mở khóa E2EE & chat không giới hạn"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
          ),
          const Divider(),
        ],

        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Đăng xuất"),
          onTap: _confirmAndLogout,
        ),
      ],
    );
  }
}
