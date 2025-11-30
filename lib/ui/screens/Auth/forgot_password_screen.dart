import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          final isLoading = viewModel.resetStatus == AuthStatus.loading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập email để nhận mã OTP đặt lại mật khẩu. Kiểm tra hộp thư để lấy mã.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await viewModel.sendResetOtp(_emailController.text);
                          if (viewModel.resetStatus == AuthStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(viewModel.resetMessage)),
                            );
                          } else if (viewModel.resetStatus ==
                              AuthStatus.error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(viewModel.resetErrorMessage)),
                            );
                          }
                        },
                  child: const Text('Gửi mã OTP'),
                ),
                const Divider(height: 32),
                const Text('Nhập mã OTP và mật khẩu mới để đặt lại.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (isLoading) const Center(child: CircularProgressIndicator()),
                if (!isLoading)
                  ElevatedButton(
                    onPressed: () async {
                      await viewModel.confirmPasswordReset(
                        otpCode: _otpController.text,
                        newPassword: _newPasswordController.text,
                        email: _emailController.text,
                      );

                      if (viewModel.resetStatus == AuthStatus.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.resetMessage)),
                        );
                        if (mounted) Navigator.of(context).pop();
                      } else if (viewModel.resetStatus == AuthStatus.error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.resetErrorMessage)),
                        );
                      }
                    },
                    child: const Text('Xác nhận đặt lại mật khẩu'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
