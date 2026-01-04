import 'package:flutter/material.dart';

class ParentShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool showTopLoading;

  const ParentShell({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.body,
    this.appBar,
    this.showTopLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          body,
          if (showTopLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Con cái'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Theo dõi'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
