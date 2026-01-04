import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/core/presentation/widgets/app_button.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_text_field.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_scaffold.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_card_section.dart';
import 'package:quan_ly_cha_con/core/presentation/widgets/app_section_header.dart';

import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/child/presentation/pages/child_main_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/data/repositories/location_repository_impl.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/pages/parent_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

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

  Future<void> _handleRegister(AuthViewModel viewModel) async {
    await viewModel.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (viewModel.status == AuthStatus.success) {
      final screen = _selectedRole == 'cha'
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
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Đăng ký',
      body: ListView(
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(
            title: 'Tạo tài khoản',
            subtitle: 'Chọn vai trò và bắt đầu sử dụng.',
          ),
          AppCardSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu (tối thiểu 6 ký tự)',
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 14),
                Text('Chọn vai trò', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Cha/Mẹ'),
                        value: 'cha',
                        groupValue: _selectedRole,
                        onChanged: isLoading ? null : (v) => setState(() => _selectedRole = v ?? 'cha'),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Con'),
                        value: 'con',
                        groupValue: _selectedRole,
                        onChanged: isLoading ? null : (v) => setState(() => _selectedRole = v ?? 'con'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  text: 'Đăng ký',
                  isLoading: isLoading,
                  onPressed: () => _handleRegister(vm),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text('Đã có tài khoản? Đăng nhập'),
          ),
        ],
      ),
    );
  }
}
