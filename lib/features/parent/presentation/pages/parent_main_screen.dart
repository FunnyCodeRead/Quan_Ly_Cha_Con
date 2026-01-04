import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/features/parent/location/presentation/screens/parent_all_children_map_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/presentation/screens/parent_location_map_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/presentation/state/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/tabs/children_tab.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/tabs/home_tab.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/tabs/settings_tab.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/widgets/child_account_form_result.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/widgets/confirm_delete_child_dialog.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/widgets/create_child_dialog.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/widgets/parent_shell.dart';


import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';

class ParentMainScreen extends StatefulWidget {
  final List<User> children;
  final LocationRepository locationRepository;

  const ParentMainScreen({
    super.key,
    required this.children,
    required this.locationRepository,
  });

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  int _selectedIndex = 0;
  User? _selectedChild;

  late final ParentLocationVm _locationVm;
  late final AuthViewModel _authVM;

  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _authVM = context.read<AuthViewModel>();
    _locationVm = ParentLocationVm(widget.locationRepository);

    _authVM.addListener(_handleAuthChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ids = _authVM.children.map((c) => c.uid).toList();
      _locationVm.watchAllChildren(ids);
    });
  }

  @override
  void dispose() {
    _authVM.removeListener(_handleAuthChange);
    _locationVm.dispose();
    super.dispose();
  }

  void _handleAuthChange() {
    final ids = _authVM.children.map((c) => c.uid).toList();
    _locationVm.watchAllChildren(ids);

    if (_selectedChild != null && !ids.contains(_selectedChild!.uid)) {
      _selectedChild = null;
    }

    if (!mounted) return;

    final status = _authVM.status;

    if (status == AuthStatus.error && _authVM.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authVM.errorMessage)),
      );
      _lastAction = null;
    } else if (status == AuthStatus.success && _lastAction != null) {
      final text = _lastAction == 'create'
          ? 'Tạo tài khoản con thành công'
          : 'Đã xóa tài khoản con';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      _lastAction = null;
    }

    setState(() {});
  }

  Future<void> _onCreateChild() async {
    final ChildAccountFormResult? form = await showCreateChildDialog(context);
    if (form == null) return;

    _lastAction = 'create';
    await _authVM.createChildAccount(
      name: form.name,
      email: form.email,
      password: form.password,
    );
  }

  Future<void> _onDeleteChild(User child) async {
    final display = child.name.isEmpty ? child.email : child.name;
    final confirmed = await showConfirmDeleteChildDialog(
      context,
      displayName: display,
    );
    if (!confirmed) return;

    _lastAction = 'delete';
    await _authVM.deleteChild(child.uid);
  }

  void _selectChildToTrack(User child) {
    setState(() {
      _selectedChild = child;
      _selectedIndex = 2;
    });
  }

  void _backToAllChildrenMap() {
    setState(() {
      _selectedChild = null;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final children = authVM.children;
    final isBusy = authVM.status == AuthStatus.loading;

    final screens = [
      const HomeTab(),
      ChildrenTab(
        children: children,
        onSelectChild: _selectChildToTrack,
        onCreateChild: isBusy ? null : _onCreateChild,
        onDeleteChild: isBusy ? null : _onDeleteChild,
        onChatChild: (child) => Navigator.pushNamed(context, '/chat', arguments: child),
      ),
      ChangeNotifierProvider.value(
        value: _locationVm,
        child: _selectedChild == null
            ? ParentAllChildrenMapScreen(children: children)
            : ParentLocationMapScreen(
          child: _selectedChild!,
          onBackToAllChildren: _backToAllChildrenMap,
        ),
      ),
      const SettingsTab(),
    ];

    return ParentShell(
      selectedIndex: _selectedIndex,
      onTabSelected: (index) {
        setState(() {
          _selectedIndex = index;
          if (index != 2) _selectedChild = null;
        });
      },
      appBar: _selectedIndex == 2 ? null : AppBar(title: const Text('Dashboard Cha/Mẹ')),
      showTopLoading: isBusy,
      body: screens[_selectedIndex],
    );
  }
}
