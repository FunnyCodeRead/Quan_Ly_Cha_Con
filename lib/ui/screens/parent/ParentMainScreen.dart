import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/models/user.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
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
  late final AuthViewModel _authViewModel;
  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _authViewModel = context.read<AuthViewModel>();
    _locationViewModel = ParentLocationViewModel(widget.locationRepository);

    _authViewModel.addListener(_handleAuthChange);
    _authViewModel.addListener(_handleChildrenChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ids = _authViewModel.children.map((c) => c.uid).toList();
      _locationViewModel.watchAllChildren(ids);
    });
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_handleAuthChange);
    _authViewModel.removeListener(_handleChildrenChange);
    _locationViewModel.dispose();
    super.dispose();
  }

  void _handleAuthChange() {
  void _handleChildrenChange() {
    final ids = _authViewModel.children.map((c) => c.uid).toList();
    _locationViewModel.watchAllChildren(ids);
    if (_selectedChild != null && !ids.contains(_selectedChild!.uid)) {
      _selectedChild = null;
    }

    if (!mounted) return;

    final status = _authViewModel.status;
    if (status == AuthStatus.error && _authViewModel.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authViewModel.errorMessage)),
      );
      _lastAction = null;
    } else if (status == AuthStatus.success && _lastAction != null) {
      final successText = _lastAction == 'create'
          ? 'Tạo tài khoản con thành công'
          : 'Đã xóa tài khoản con';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText)),
      );
      _lastAction = null;
    }

    setState(() {});
  }

  Future<void> _showCreateChildDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final authVM = context.watch<AuthViewModel>();
        return AlertDialog(
          title: const Text('Tạo tài khoản con'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên con'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: authVM.status == AuthStatus.loading
                  ? null
                  : () async {
                      _lastAction = 'create';
                      await _authViewModel.createChildAccount(
                        name: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      if (mounted && _authViewModel.status == AuthStatus.success) {
                        Navigator.of(context).pop();
                      }
                    },
              onPressed: () async {
                await _authViewModel.createChildAccount(
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                );
                if (mounted && _authViewModel.status == AuthStatus.success) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteChild(User child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản con'),
        content: Text('Bạn có chắc muốn xóa ${child.name.isEmpty ? child.email : child.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _lastAction = 'delete';
      await _authViewModel.deleteChild(child.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final children = authVM.children;
    final isBusy = authVM.status == AuthStatus.loading;
    final children = context.watch<AuthViewModel>().children;
    final screens = [
      const HomeTab(),

      // Tab Con cái: bấm con nào -> focus con đó
      ChildrenTab(
        children: children,
        onSelectChild: (child) {
          setState(() {
            _selectedChild = child;
            _selectedIndex = 2; // tab map
          });
        },
        onCreateChild: isBusy ? null : _showCreateChildDialog,
        onDeleteChild: isBusy ? null : _confirmDeleteChild,
        onCreateChild: _showCreateChildDialog,
        onDeleteChild: _confirmDeleteChild,
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
          children: children,
          focusChildId: _selectedChild?.uid, // focus nếu có chọn
        ),
      ),

      const SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Cha/Mẹ')),
      body: Stack(
        children: [
          screens[_selectedIndex],
          if (isBusy)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
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
