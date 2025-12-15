import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/forgot_password_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/register_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/ui/screens/parent/ParentMainScreen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'package:quan_ly_cha_con/viewmodel/children/child_location_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

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

  Future<void> _handleLogin(BuildContext context, AuthViewModel viewModel) async {
    await viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (viewModel.status == AuthStatus.success) {
      final role = viewModel.currentUser?.role;

      if (role == 'con') {
        try {
          await context.read<ChildLocationViewModel>().startLocationSharing();
        } catch (e) {
          debugPrint("Start sharing after login failed: $e");
        }
      }

      final screen = role == 'cha'
          ? ParentMainScreen(
        children: viewModel.children,
        locationRepository: LocationRepositoryImpl(),
      )
          : const ChildMainScreen();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
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
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                if (viewModel.status == AuthStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () => _handleLogin(context, viewModel),
                    child: const Text('Đăng Nhập'),
                  ),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Quên mật khẩu? Gửi mã OTP'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
