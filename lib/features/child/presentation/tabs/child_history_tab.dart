// lib/features/child/presentation/tabs/child_history_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';

class ChildHistoryTab extends StatelessWidget {
  const ChildHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final locationVM = context.watch<ChildLocationViewModel>();
    final cs = Theme.of(context).colorScheme;

    final childId = authVM.currentUser?.uid ?? '';

    if (childId.isEmpty) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    return FutureBuilder<List<LocationData>>(
      future: locationVM.loadLocationHistory(childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Không có lịch sử vị trí',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final loc = list[index];
            final dt = DateTime.fromMillisecondsSinceEpoch(loc.timestamp);

            return Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(Icons.location_on, color: cs.primary),
                title: Text(
                  '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  dt.toString(),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                trailing: Text(
                  '${loc.accuracy.toStringAsFixed(0)}m',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
