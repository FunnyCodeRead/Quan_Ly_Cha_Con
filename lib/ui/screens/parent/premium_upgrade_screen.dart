import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isPremium = authVM.isPremiumParent;

    return Scaffold(
      appBar: AppBar(title: const Text("Nâng cấp Premium")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Premium mở khóa bảo mật tin nhắn",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text("✅ Nhắn tin không giới hạn"),
            const Text("✅ Mã hóa đầu-cuối (E2EE)"),
            const Text("✅ Chỉ cha/mẹ cần nâng cấp"),
            const SizedBox(height: 24),

            if (isPremium)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  "Bạn đã là Premium 🎉",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: authVM.status == AuthStatus.loading
                      ? const CircularProgressIndicator()
                      : const Text("Nâng cấp Premium (Demo)"),
                  onPressed: authVM.status == AuthStatus.loading
                      ? null
                      : () async {
                    await context.read<AuthViewModel>().upgradePremium();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Đã nâng cấp Premium!")),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
