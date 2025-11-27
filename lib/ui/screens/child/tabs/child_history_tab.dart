import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/models/location_data.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'package:quan_ly_cha_con/viewmodel/children/child_location_view_model.dart';

class ChildHistoryTab extends StatelessWidget {
  const ChildHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final locationVM = context.watch<ChildLocationViewModel>();
    final childId = authVM.currentUser?.uid ?? '';

    return FutureBuilder<List<LocationData>>(
      future: locationVM.loadLocationHistory(childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có lịch sử vị trí'));
        }

        final history = snapshot.data!;
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final loc = history[index];
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}'),
              subtitle: Text(DateTime.fromMillisecondsSinceEpoch(loc.timestamp).toString()),
            );
          },
        );
      },
    );
  }
}
