import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/repositories/athu/auth_repository.dart';
import 'package:quan_ly_cha_con/services/auth/session_manager.dart';
import 'package:quan_ly_cha_con/ui/screens/Auth/login_screen.dart';
import 'package:quan_ly_cha_con/ui/screens/child/ChildMainScreen.dart';
import 'package:quan_ly_cha_con/viewmodel/auth/auth_view_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final sessionManager = await SessionManager.init();

  runApp(MyApp(sessionManager: sessionManager));
}

class MyApp extends StatelessWidget {
  final SessionManager sessionManager;

  const MyApp({required this.sessionManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionManager>(create: (_) => sessionManager),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            authRepository: AuthRepositoryImpl(),
            sessionManager: sessionManager,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Child Tracker',
        theme: ThemeData(useMaterial3: true),
        home: _buildHome(sessionManager),
      ),
    );
  }

  Widget _buildHome(SessionManager sessionManager) {
    return sessionManager.isLoggedIn
        ? const SplashScreen()
        : const LoginScreen();
  }
}

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

    if (mounted) {
      final viewModel = context.read<AuthViewModel>();
      await viewModel.loadUserFromStorage();

      if (mounted) {
        final role = viewModel.currentUser?.role;
        final screen = role == 'cha'
            ? const ParentMainScreen()
            : const ChildMainScreen();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => screen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ParentMainScreen extends StatelessWidget {
  const ParentMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Cha/Mẹ')),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Xin chào ${viewModel.currentUser?.name}'),
                const SizedBox(height: 20),
                Text('Số con: ${viewModel.children.length}'),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    await viewModel.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}