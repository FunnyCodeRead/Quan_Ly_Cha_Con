import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/main.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'cha';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                const Text('Chọn vai trò:'),
                RadioListTile<String>(
                  title: const Text('Cha/Mẹ'),
                  value: 'cha',
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() => _selectedRole = value ?? 'cha');
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Con'),
                  value: 'con',
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() => _selectedRole = value ?? 'cha');
                  },
                ),
                const SizedBox(height: 24),
                if (viewModel.status == AuthStatus.loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      await viewModel.register(
                        email: _emailController.text,
                        password: _passwordController.text,
                        role: _selectedRole,
                      );

                      if (viewModel.status == AuthStatus.success) {
                        if (mounted) {
                          final screen = _selectedRole == 'cha'
                              ? const ParentMainScreen()
                              : const ChildMainScreen();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => screen),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage)),
                        );
                      }
                    },
                    child: const Text('Đăng Ký'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}