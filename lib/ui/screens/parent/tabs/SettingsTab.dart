import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/ui/widgets/logout_action.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'package:quan_ly_cha_con/routes/app_routes.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool confirmUploads = true;

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          if (showChevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1);

  Future<void> _confirmAndLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đăng xuất"),
          ),
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

    return SafeArea(
      child: ListView(
        children: [
          // ===== Confirmations =====
          _sectionTitle("Confirmations"),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: Colors.black87,
            ),
            title: const Text("Confirm Uploads",
                style: TextStyle(fontSize: 15)),
            trailing: Switch(
              value: confirmUploads,
              onChanged: (v) => setState(() => confirmUploads = v),
            ),
          ),

          _divider(),

          // ===== Account =====
          _sectionTitle("Account"),

          // ✅ Premium tile (chỉ CHA thấy)
          if (isParent) ...[
            _tile(
              icon: Icons.workspace_premium,
              title: isPremium ? "Premium: Đang hoạt động" : "Nâng cấp Premium",
              subtitle: "Mở khóa E2EE & chat không giới hạn",
              trailingText: isPremium ? "ON" : null,
              onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
            ),
            _divider(),
          ],

          // ===== Logout tile (dùng chung logic) =====
          _tile(
            icon: Icons.logout,
            title: "Đăng xuất",
            showChevron: false,
            onTap: _confirmAndLogout,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
