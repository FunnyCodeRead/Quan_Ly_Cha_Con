import 'package:flutter/material.dart';

Future<bool> showConfirmDeleteChildDialog(
    BuildContext context, {
      required String displayName,
    }) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xóa tài khoản con'),
      content: Text('Bạn có chắc muốn xóa $displayName?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );

  return confirmed == true;
}
