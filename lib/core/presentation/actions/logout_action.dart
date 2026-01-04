import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/pages/login_screen.dart';
import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';

/// Logout dùng chung cho toàn app (cha / con)
/// - Con: stop share location trước
/// - Auth: signOut + clear session
/// - Điều hướng về Login và clear stack
Future<void> logoutAction(BuildContext context) async {
  final authVM = context.read<AuthViewModel>();

  try {
    // Nếu là con -> dừng chia sẻ trước để tránh stream chạy nền
    if (authVM.currentUser?.role == 'con') {
      try {
        await context.read<ChildLocationViewModel>().stopSharingOnLogout();
      } catch (_) {
        // ignore: stop sharing fail vẫn logout tiếp
      }
    }

    await authVM.logout(context);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng xuất thất bại: $e')),
    );
  }
}
