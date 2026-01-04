// lib/features/child/presentation/pages/child_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';

import '../tabs/child_location_tab.dart';
import '../tabs/child_history_tab.dart';
import '../tabs/child_messages_tab.dart';
import '../tabs/child_account_tab.dart';

class ChildMainScreen extends StatefulWidget {
  const ChildMainScreen({super.key});

  @override
  State<ChildMainScreen> createState() => _ChildMainScreenState();
}

class _ChildMainScreenState extends State<ChildMainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _startedSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSharingOnce());
  }

  void _startSharingOnce() {
    if (_startedSharing) return;
    _startedSharing = true;

    final authVM = context.read<AuthViewModel>();
    final childId = authVM.currentUser?.uid ?? '';
    if (childId.isEmpty) return;

    context.read<ChildLocationViewModel>().startLocationSharing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản Con'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Vị trí'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
            Tab(icon: Icon(Icons.message), text: 'Tin nhắn'),
            Tab(icon: Icon(Icons.person), text: 'Tài khoản'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChildLocationTab(),
          ChildHistoryTab(),
          ChildMessagesTab(),
          ChildAccountTab(),
        ],
      ),
    );
  }
}
