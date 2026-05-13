import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int    _tab         = 0;
  int    _prevTab     = 0;
  int?   _userId;
  String _email       = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await AuthService.getUser();
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }
    setState(() {
      _userId      = user['userId'];
      _email       = user['email'];
      _displayName = user['displayName'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final tabs = [
      DashboardScreen(userId: _userId!, email: _email, displayName: _displayName),
      FriendsScreen(userId: _userId!),
      LeaderboardScreen(userId: _userId!),
      ShopScreen(userId: _userId!),
      SettingsScreen(userId: _userId!, email: _email),
    ];

    return Scaffold(
      body: Stack(
        children: List.generate(tabs.length, (i) {
          final isActive = i == _tab;
          return IgnorePointer(
            ignoring: !isActive,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.0,
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.97,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox.expand(child: tabs[i]),
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          SoundService.playTap();
          setState(() { _prevTab = _tab; _tab = i; });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forest_rounded),      label: 'Bäume'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded),  label: 'Freunde'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded),label: 'Rangliste'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded),  label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),    label: 'Einstellungen'),
        ],
      ),
    );
  }
}
