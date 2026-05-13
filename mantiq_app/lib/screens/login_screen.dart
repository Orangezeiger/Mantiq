import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading  = false;

  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  final _nameCtrl  = TextEditingController();
  String? _fehler;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw    = _pwCtrl.text;
    final name  = _nameCtrl.text.trim();

    if (email.isEmpty || pw.isEmpty) {
      setState(() => _fehler = 'Bitte alle Felder ausfüllen.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _fehler = 'Bitte einen Nutzernamen eingeben.');
      return;
    }
    if (!_isLogin && pw.length < 6) {
      setState(() => _fehler = 'Passwort muss mindestens 6 Zeichen lang sein.');
      return;
    }

    setState(() { _loading = true; _fehler = null; });

    final result = _isLogin
        ? await ApiService.login(email, pw)
        : await ApiService.register(email, pw, name);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result['ok']) {
      setState(() => _fehler = result['data']['fehler'] ?? 'Fehler aufgetreten.');
      return;
    }

    if (_isLogin) {
      final data = result['data'];
      await AuthService.saveUser(
        data['userId'],
        data['email'],
        data['displayName'] ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _isLogin = true;
        _fehler  = null;
        _pwCtrl.clear();
        _nameCtrl.clear();
      });
      _showSnack('Registrierung erfolgreich – jetzt anmelden!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.surface2,
               behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Logo
                Column(children: [
                  Text('mantiq',
                    style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w900,
                      color: AppColors.primary, letterSpacing: -2,
                    )),
                  const SizedBox(height: 4),
                  Text('Lern wie ein Macher',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                const SizedBox(height: 40),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [

                    // Tabs
                    Row(children: [
                      _tab('Anmelden',     _isLogin,  () => setState(() { _isLogin = true;  _fehler = null; })),
                      const SizedBox(width: 8),
                      _tab('Registrieren', !_isLogin, () => setState(() { _isLogin = false; _fehler = null; })),
                    ]),
                    const SizedBox(height: 24),

                    // Fehler
                    if (_fehler != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F1F1F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF5A2B2B)),
                        ),
                        child: Text(_fehler!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nutzername (nur bei Registrierung)
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(hintText: 'Nutzername'),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // E-Mail
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(hintText: 'E-Mail'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),

                    // Passwort
                    TextField(
                      controller: _pwCtrl,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: _isLogin ? 'Passwort' : 'Passwort (min. 6 Zeichen)',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_isLogin ? 'Anmelden' : 'Account erstellen'),
                      ),
                    ),

                  ]),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 14, fontWeight: FontWeight.w600,
            )),
        ),
      ),
    );
  }
}
