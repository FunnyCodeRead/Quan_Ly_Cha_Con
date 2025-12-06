import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

Future<void> logoutAction(BuildContext context) async {
  await context.read<AuthViewModel>().logout(context);
  if (!context.mounted) return;

  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
        (route) => false,
  );
}
