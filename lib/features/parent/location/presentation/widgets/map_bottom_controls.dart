import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';

class MapBottomControls extends StatelessWidget {
  final List<User> children;
  final ValueChanged<User> onTapChild;
  final VoidCallback onMore;
  final VoidCallback onMyLocation;

  const MapBottomControls({
    super.key,
    required this.children,
    required this.onTapChild,
    required this.onMore,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final c in children)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(c.name.isNotEmpty ? c.name : c.email),
                          onPressed: () => onTapChild(c),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(onPressed: onMyLocation, icon: const Icon(Icons.my_location)),
            IconButton(onPressed: onMore, icon: const Icon(Icons.more_horiz)),
          ],
        ),
      ),
    );
  }
}
