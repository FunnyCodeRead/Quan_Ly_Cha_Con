import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';

class ChildrenPickerSheet extends StatelessWidget {
  final List<User> children;
  final Map<String, LocationData> latestMap;

  /// latest chắc chắn non-null khi gọi
  final void Function(User child, LocationData latest) onPick;

  const ChildrenPickerSheet({
    super.key,
    required this.children,
    required this.latestMap,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: children.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final child = children[i];
            final latest = latestMap[child.uid]; // LocationData?
            return ListTile(
              title: Text(child.name.isNotEmpty ? child.name : child.email),
              subtitle: latest == null
                  ? const Text('Chưa có vị trí')
                  : Text(
                'Lat ${latest.latitude.toStringAsFixed(4)} • Lng ${latest.longitude.toStringAsFixed(4)}',
              ),
              onTap: latest == null ? null : () => onPick(child, latest),
            );
          },
        ),
      ),
    );
  }
}
