import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/pages/login_screen.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/chat/presentation/pages/chat_screen.dart';
import 'package:quan_ly_cha_con/features/child/presentation/pages/child_main_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/data/repositories/location_repository_impl.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/pages/parent_main_screen.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/pages/premium_upgrade_screen.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';



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
