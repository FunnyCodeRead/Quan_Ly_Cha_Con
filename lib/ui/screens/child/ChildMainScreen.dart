import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/login_screen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class ChildMainScreen extends StatelessWidget {
  const ChildMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Con')),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Xin chào ${viewModel.currentUser?.name}'),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    await viewModel.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}