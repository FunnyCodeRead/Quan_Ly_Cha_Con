import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/models/user.dart';

import 'package:quan_ly_cha_con/ui/screens/Auth/login_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/ui/screens/parent/ParentMainScreen.dart';
import 'package:quan_ly_cha_con/ui/screens/chat/chat_screen.dart';

import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/ui/screens/parent/premium_upgrade_screen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class AppRoutes {
  static const login = '/login';
  static const childHome = '/child';
  static const parentHome = '/parent';
  static const chat = '/chat';
  static const premium = '/premium';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    childHome: (_) => const ChildMainScreen(),

    parentHome: (context) {
      final authVM = context.read<AuthViewModel>();
      return ParentMainScreen(
        children: authVM.children,
        locationRepository: LocationRepositoryImpl(),
      );
    },

    premium: (_) => const PremiumUpgradeScreen(),

    chat: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! User) {
        return const Scaffold(
          body: Center(child: Text("Không tìm thấy thông tin con để chat")),
        );
      }
      final child = args;
      return ChatScreen(child: child);
    },
  };
}
