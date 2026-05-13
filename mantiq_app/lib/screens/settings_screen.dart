import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int    userId;
  final String email;
  const SettingsScreen({super.key, required this.userId, required this.email});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await ApiService.getUser(widget.userId);
    setState(() { _profile = p; _loading = false; });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
    }
  }

  void _editName() {
    final daysLeft = (_profile?['daysUntilNameChange'] as num?)?.toInt() ?? 0;
    if (daysLeft > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Anzeigename kann erst in $daysLeft Tagen wieder geändert werden.'),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final ctrl = TextEditingController(text: _profile?['displayName'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Anzeigename', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Dein Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.updateDisplayName(widget.userId, ctrl.text.trim());
              if (!mounted) return;
              if (res['ok'] == false) {
                final daysLeft = res['data']?['daysLeft'] as int? ?? 30;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Erst in $daysLeft Tagen wieder änderbar.'),
                  backgroundColor: AppColors.surface2,
                  behavior: SnackBarBehavior.floating,
                ));
              }
              _load();
            },
            child: const Text('Speichern', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Fortschritt zurücksetzen?', style: TextStyle(color: AppColors.text)),
        content: const Text(
            'Alle abgeschlossenen Schritte werden gelöscht. XP und Coins bleiben erhalten.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.resetProgress(widget.userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fortschritt zurückgesetzt'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Zurücksetzen', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('✨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Mantiq Pro',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Unbegrenzte Bäume · Prioritäts-Support · Exklusive Items',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final res = await ApiService.upgradeSubscription();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['data']['nachricht'] ?? ''),
                  backgroundColor: AppColors.surface2,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Pro freischalten – kommt bald!'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // Profil-Karte
                  _ProfileCard(
                    email:   widget.email,
                    name:    _profile?['displayName'] ?? '',
                    xp:      _profile?['xp'] ?? 0,
                    coins:   _profile?['coins'] ?? 0,
                    streak:  _profile?['streakDays'] ?? 0,
                    isPro:   _profile?['subscriptionPlan'] == 'PRO',
                    onEditName: _editName,
                  ),
                  const SizedBox(height: 20),

                  // Konto
                  _SectionLabel('Konto'),
                  _SettingsItem(
                    icon: Icons.badge_outlined, label: 'Anzeigename ändern',
                    onTap: _editName),
                  _SettingsItem(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Mantiq Pro',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99)),
                      child: const Text('Bald', style: TextStyle(
                          color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    onTap: _showSubscriptionInfo),
                  const SizedBox(height: 16),

                  // Fortschritt
                  _SectionLabel('Lernfortschritt'),
                  _SettingsItem(
                    icon: Icons.restart_alt_rounded,
                    label: 'Fortschritt zurücksetzen',
                    textColor: AppColors.error,
                    onTap: _confirmResetProgress),
                  const SizedBox(height: 16),

                  // Session
                  _SectionLabel('Session'),
                  _SettingsItem(
                    icon: Icons.logout_rounded,
                    label: 'Abmelden',
                    textColor: AppColors.error,
                    onTap: _logout),
                ],
              ),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String email;
  final String name;
  final int    xp;
  final int    coins;
  final int    streak;
  final bool   isPro;
  final VoidCallback onEditName;

  const _ProfileCard({
    required this.email, required this.name, required this.xp,
    required this.coins, required this.streak, required this.isPro,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : email;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Avatar
        GestureDetector(
          onTap: onEditName,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15),
              border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
            ),
            child: Center(child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 30, fontWeight: FontWeight.w900),
            )),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(displayName,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
          if (isPro) ...[
            const SizedBox(width: 6),
            const Text('✨', style: TextStyle(fontSize: 14)),
          ],
        ]),
        Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 16),
        // Stats
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('⚡', '$xp', 'XP'),
          _divider(),
          _stat('💰', '$coins', 'Münzen'),
          _divider(),
          _stat('🔥', '$streak', 'Streak'),
        ]),
      ]),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      Text(value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]);
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: AppColors.border);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   textColor;
  final Widget?  trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon, required this.label, required this.onTap,
    this.textColor, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: textColor ?? AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: TextStyle(color: textColor ?? AppColors.text, fontSize: 15))),
          trailing ?? Icon(Icons.chevron_right_rounded,
              color: AppColors.border, size: 20),
        ]),
      ),
    );
  }
}
