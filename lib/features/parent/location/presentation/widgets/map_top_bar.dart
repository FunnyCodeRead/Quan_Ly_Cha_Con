import 'package:flutter/material.dart';

class MapTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onAvatarTap;

  const MapTopBar({
    super.key,
    this.title = 'Vị trí',
    required this.onMenuTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: topInset + 48, // gồm cả status bar
        color: Colors.white,   // nền trắng phủ luôn vùng status bar
        child: Column(
          children: [
            SizedBox(height: topInset),
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: onMenuTap,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.menu, size: 22),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onAvatarTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
