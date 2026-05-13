import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  try { await NotificationService.init(); } catch (_) {}
  runApp(const MantiqApp());
}

class MantiqApp extends StatelessWidget {
  const MantiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mantiq',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _StartScreen(),
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getUser(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        if (snapshot.data != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
