// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quan_ly_cha_con/routes/app_routes.dart';
import 'package:quan_ly_cha_con/repositories/athu/auth_repository.dart';
import 'package:quan_ly_cha_con/repositories/location_repository.dart';
import 'package:quan_ly_cha_con/services/auth/session_manager.dart';
import 'package:quan_ly_cha_con/services/location_service_location_pkg.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/login_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/ui/screens/parent/ParentMainScreen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'package:quan_ly_cha_con/viewmodel/parent/parent_location_view_model.dart';
import 'package:quan_ly_cha_con/viewmodel/children/child_location_view_model.dart';


import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final sessionManager = await SessionManager.init();
  runApp(MyApp(sessionManager: sessionManager));
}

class MyApp extends StatelessWidget {
  final SessionManager sessionManager;
  const MyApp({required this.sessionManager, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionManager>(create: (_) => sessionManager),

        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepository: AuthRepositoryImpl(),
            sessionManager: sessionManager,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ParentLocationViewModel(LocationRepositoryImpl()),
        ),


        ChangeNotifierProvider(
          create: (_) => ChildLocationViewModel(
            LocationRepositoryImpl(),
            LocationServiceImpl(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        routes: AppRoutes.routes,
        home: _startScreen(sessionManager),
      ),
    );
  }

  Widget _startScreen(SessionManager sessionManager) {
    return sessionManager.isLoggedIn
        ? const SplashScreen()
        : const LoginScreen();
  }
}

// =============================
// SPLASH – kiểm tra role và điều hướng
// =============================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final authVM = context.read<AuthViewModel>();
    await authVM.loadUserFromStorage();
    if (!mounted) return;

    final role = authVM.currentUser?.role;

    final nextScreen = role == "cha"
        ? ParentMainScreen(
      children: authVM.children,
      locationRepository: LocationRepositoryImpl(),
    )
        : const ChildMainScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
