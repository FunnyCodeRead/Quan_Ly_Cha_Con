import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/app/router/app_routes.dart';
import 'package:quan_ly_cha_con/core/services/location/location_service.dart';
import 'package:quan_ly_cha_con/core/services/session_manager.dart';
import 'package:quan_ly_cha_con/core/theme/app_theme.dart';
import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:quan_ly_cha_con/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:quan_ly_cha_con/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:quan_ly_cha_con/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/pages/login_screen.dart';
import 'package:quan_ly_cha_con/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:quan_ly_cha_con/features/child/presentation/pages/child_main_screen.dart';
import 'package:quan_ly_cha_con/features/parent/location/data/repositories/location_repository_impl.dart';


import 'package:quan_ly_cha_con/features/child/location/presentation/state/child_location_view_model.dart';


import 'package:quan_ly_cha_con/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:quan_ly_cha_con/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:quan_ly_cha_con/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:quan_ly_cha_con/features/chat/domain/repositories/chat_repository.dart';
import 'package:quan_ly_cha_con/features/chat/presentation/viewmodel/chat_view_model.dart';
import 'package:quan_ly_cha_con/features/parent/presentation/pages/parent_main_screen.dart';

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

        // ✅ Auth datasources
        Provider<AuthRemoteDataSource>(
          create: (_) => AuthRemoteDataSourceImpl(),
        ),
        Provider<AuthLocalDataSource>(
          create: (ctx) => AuthLocalDataSourceImpl(
            ctx.read<SessionManager>(),
          ),
        ),

        // ✅ Auth repository (inject remote + local)
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            remote: ctx.read<AuthRemoteDataSource>(),
            local: ctx.read<AuthLocalDataSource>(),
          ),
        ),

        // ✅ AuthViewModel (inject repository)
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            authRepository: ctx.read<AuthRepository>(),
            sessionManager: ctx.read<SessionManager>(),
          ),
        ),


        // ✅ CHAT PROVIDERS
        Provider<ChatRepository>(
          create: (_) => ChatRepositoryImpl(
            remote: ChatRemoteDataSourceImpl(),
            local: ChatLocalDataSourceImpl(),
          ),
        ),
        ChangeNotifierProvider<ChildLocationViewModel>(
          create: (_) => ChildLocationViewModel(
            LocationRepositoryImpl(),
            LocationServiceImpl(),
          ),
        ),


      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(seed: Colors.blue),
        darkTheme: AppTheme.dark(seed: Colors.blue),

        themeMode: ThemeMode.system,
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

    if (role == "con") {
      try {
        await context.read<ChildLocationViewModel>().startLocationSharing();
      } catch (e) {
        debugPrint("Start sharing from splash failed: $e");
      }
    }

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
