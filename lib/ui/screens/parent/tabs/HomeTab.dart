// lib/ui/screens/parent/tabs/home_tab.dart
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder dashboard
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Dashboard Cha/Mẹ', style: TextStyle(fontSize: 20)),
            SizedBox(height: 12),
            Text('Ở đây hiển thị thông tin tổng quan: số con, cảnh báo, v.v.'),
          ],
        ),
      ),
    );
  }
}
