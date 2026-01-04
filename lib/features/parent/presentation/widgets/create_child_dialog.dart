import 'package:flutter/material.dart';
import 'child_account_form_result.dart';

Future<ChildAccountFormResult?> showCreateChildDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  return showDialog<ChildAccountFormResult>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Tạo tài khoản con'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên con')),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(
            controller: passCtrl,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              ChildAccountFormResult(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                password: passCtrl.text.trim(),
              ),
            );
          },
          child: const Text('Tạo'),
        ),
      ],
    ),
  );
}
