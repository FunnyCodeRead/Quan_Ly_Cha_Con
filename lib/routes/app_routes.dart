import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/login_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/ui/screens/parent/ParentMainScreen.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';

class AppRoutes {
  static const login = '/login';
  static const childHome = '/child';
  static const parentHome = '/parent';

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
  };
}
