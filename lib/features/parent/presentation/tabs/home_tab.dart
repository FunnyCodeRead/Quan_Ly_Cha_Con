import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        margin: const EdgeInsets.all(16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dashboard Cha/Mẹ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              Text('Ở đây hiển thị tổng quan: số con, cảnh báo, v.v.'),
            ],
          ),
        ),
      ),
    );
  }
}
