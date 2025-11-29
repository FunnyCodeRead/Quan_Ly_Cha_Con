import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/user.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';

import 'tabs/HomeTab.dart';
import 'tabs/ChildrenTab.dart';
import 'tabs/SettingsTab.dart';
import 'tabs/parent_all_children_map_screen.dart';

class ParentMainScreen extends StatefulWidget {
  final List<User> children;
  final LocationRepository locationRepository;

  const ParentMainScreen({
    Key? key,
    required this.children,
    required this.locationRepository,
  }) : super(key: key);

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _selectedIndex = 0;
  User? _selectedChild;

  late final ParentLocationViewModel _locationViewModel;

  @override
  void initState() {
    super.initState();
    _locationViewModel = ParentLocationViewModel(widget.locationRepository);

    // Watch all children ngay từ đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ids = widget.children.map((c) => c.uid).toList();
      _locationViewModel.watchAllChildren(ids);
    });
  }

  @override
  void dispose() {
    _locationViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeTab(),

      // Tab Con cái: bấm con nào -> focus con đó
      ChildrenTab(
        children: widget.children,
        onSelectChild: (child) {
          setState(() {
            _selectedChild = child;
            _selectedIndex = 2; // tab map
          });
        },
        onChatChild: (child) {
          // C1: nếu dùng routes
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: child, // truyền thông tin con sang màn chat
          );

          // C2: nếu dùng MaterialPageRoute
          // Navigator.of(context).push(
          //   MaterialPageRoute(builder: (_) => ChatScreen(child: child)),
          // );
        },
      ),


      // Tab Theo dõi: multi children map
      ChangeNotifierProvider.value(
        value: _locationViewModel,
        child: ParentAllChildrenMapScreen(
          children: widget.children,
          focusChildId: _selectedChild?.uid, // focus nếu có chọn
        ),
      ),

      const SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Cha/Mẹ')),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 2) _selectedChild = null; // rời tab map thì bỏ focus
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom), label: 'Con cái'),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: 'Theo dõi'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
