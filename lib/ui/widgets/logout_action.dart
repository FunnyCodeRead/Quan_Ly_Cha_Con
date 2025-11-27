import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

Future<void> logoutAction(BuildContext context) async {
  await context.read<AuthViewModel>().logout();
  if (!context.mounted) return;

  // ✅ về login bằng named route
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
        (route) => false,
  );

  // SnackBar: nên show sau khi về login thì mới chắc ăn.
  // Nhưng để đơn giản bạn có thể bỏ SnackBar ở đây, hoặc show trước khi navigate.
}
