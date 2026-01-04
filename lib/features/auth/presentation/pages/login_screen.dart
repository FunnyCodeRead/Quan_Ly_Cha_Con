import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/core/presentation/widgets/app_button.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_text_field.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_scaffold.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_card_section.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_section_header.dart';

import 'package:quan_ly_cha_con/features/auth/presentation/pages/register_screen.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';
import 'package:quan_ly_cha_con/features/child/presentation/pages/child_main_screen.dart';

import 'package:quan_ly_cha_con/features/parent/location/data/repositories/location_repository_impl.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/pages/parent_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

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

  Future<void> _handleLogin(AuthViewModel viewModel) async {
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
        } catch (_) {}
      }

      final screen = role == 'cha'
          ? ParentMainScreen(
        children: viewModel.children,
        locationRepository: LocationRepositoryImpl(),
      )
          : const ChildMainScreen();

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final isLoading = vm.status == AuthStatus.loading;

    return AppScaffold(
      title: 'Đăng nhập',
      body: ListView(
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(
            title: 'Chào bạn 👋',
            subtitle: 'Đăng nhập để tiếp tục theo dõi và nhắn tin.',
          ),
          AppCardSection(
            child: Column(
              children: [
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onSubmitted: (_) => _handleLogin(vm),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  text: 'Đăng nhập',
                  isLoading: isLoading,
                  onPressed: () => _handleLogin(vm),
                ),
              ],
            ),
          ),
          // TextButton(
          //   onPressed: isLoading
          //       ? null
          //       : () => Navigator.of(context).push(
          //     MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          //   ),
          //   child: const Text('Quên mật khẩu? Gửi mã OTP'),
          // ),
          TextButton(
            onPressed: isLoading
                ? null
                : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('Chưa có tài khoản? Đăng ký'),
          ),
        ],
      ),
    );
  }
}
