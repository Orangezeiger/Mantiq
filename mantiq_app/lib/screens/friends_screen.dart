import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'groups_screen.dart';

class FriendsScreen extends StatefulWidget {
  final int userId;
  const FriendsScreen({super.key, required this.userId});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _friends  = [];
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final f = await ApiService.getFriends(widget.userId);
    final r = await ApiService.getFriendRequests(widget.userId);
    setState(() { _friends = f; _requests = r; _loading = false; });
  }

  void _showFriendProfile(dynamic f) {
    final name   = f['name'] as String? ?? f['email'] as String;
    final xp     = f['xp'] as int? ?? 0;
    final streak = f['streakDays'] as int? ?? 0;
    final friendshipId = f['friendshipId'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: Center(child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                    color: AppColors.primary))),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.text)),
            const SizedBox(height: 20),
            // Stats
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _statBadge(Icons.bolt_rounded, '$xp XP', AppColors.warning),
              _statBadge(Icons.local_fire_department, '$streak Tage Streak', AppColors.error),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.removeFriend(friendshipId);
                  _load();
                },
                icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                label: const Text('Freund entfernen',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  void _showAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddFriendSheet(userId: widget.userId, onSent: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freunde & Gruppen'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            const Tab(text: 'Freunde'),
            Tab(text: _requests.isEmpty ? 'Anfragen' : 'Anfragen (${_requests.length})'),
            const Tab(text: 'Gruppen'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildFriendsList(),
                _buildRequests(),
                GroupsScreen(userId: widget.userId, embedded: true),
              ],
            ),
      floatingActionButton: _tabs.index < 2
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _showAddFriendSheet,
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('👥', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Noch keine Freunde', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          SizedBox(height: 6),
          Text('Tippe + um jemanden hinzuzufügen',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final f = _friends[i];
          return _FriendCard(
            name:     f['name'] ?? f['email'],
            xp:       f['xp'] ?? 0,
            streak:   f['streakDays'] ?? 0,
            onTap:    () => _showFriendProfile(f),
            onRemove: () async {
              await ApiService.removeFriend(f['friendshipId']);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _buildRequests() {
    if (_requests.isEmpty) {
      return const Center(
        child: Text('Keine offenen Anfragen', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final r = _requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['name'] ?? r['email'],
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
              Text(r['email'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            TextButton(
              onPressed: () async {
                await ApiService.removeFriend(r['requestId']);
                _load();
              },
              child: const Text('Ablehnen', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.acceptFriendRequest(r['requestId']);
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              child: const Text('Annehmen', style: TextStyle(fontSize: 13)),
            ),
          ]),
        );
      },
    );
  }
}

// ── Freund-Suche Bottom Sheet ────────────────────────
class _AddFriendSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onSent;
  const _AddFriendSheet({required this.userId, required this.onSent});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    if (val.trim().length < 2) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final r = await ApiService.searchUsers(val.trim(), widget.userId);
      if (mounted) setState(() { _results = r; _searching = false; });
    });
  }

  Future<void> _sendRequest(dynamic user) async {
    final res = await ApiService.sendFriendRequest(widget.userId, user['email'] as String);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    widget.onSent();
    messenger.showSnackBar(SnackBar(
      content: Text(res['ok']
          ? 'Anfrage an ${user['name']} gesendet!'
          : (res['data']['fehler'] ?? 'Fehler')),
      backgroundColor: res['ok'] ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _ctrl.text.trim().length >= 2;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Freund hinzufügen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Name oder E-Mail suchen…',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)))
                : null,
          ),
          onChanged: _onChanged,
        ),
        const SizedBox(height: 4),
        if (hasQuery && !_searching && _results.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Keine Nutzer gefunden',
              style: TextStyle(color: AppColors.textMuted)),
          )
        else if (_results.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _results.length,
            itemBuilder: (_, i) {
              final u = _results[i];
              final name = (u['name'] as String?) ?? (u['email'] as String);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                ),
                title: Text(name,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                subtitle: Text(u['email'] as String,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
                  onPressed: () => _sendRequest(u),
                ),
                onTap: () => _sendRequest(u),
              );
            },
          ),
      ]),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final String name;
  final int    xp;
  final int    streak;
  final VoidCallback  onRemove;
  final VoidCallback? onTap;

  const _FriendCard({required this.name, required this.xp,
      required this.streak, required this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.15),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.bolt, color: AppColors.warning, size: 14),
            Text('$xp XP', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.local_fire_department, color: AppColors.error, size: 14),
            Text(' $streak Tage', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ])),
        IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: AppColors.textMuted, size: 20),
          onPressed: onRemove,
        ),
      ]),
    ));
  }
}
