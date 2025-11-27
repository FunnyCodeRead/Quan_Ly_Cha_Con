import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/ui/widgets/logout_action.dart';

class Logout extends StatelessWidget {
  const Logout({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('Đăng xuất'),
        onPressed: () => logoutAction(context),
      ),
    );
  }
}
