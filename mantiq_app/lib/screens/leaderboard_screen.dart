import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final int userId;
  const LeaderboardScreen({super.key, required this.userId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _claiming = false;

  static const _ligaColors = [
    Color(0xFFCD7F32), // Bronze
    Color(0xFFB0C4DE), // Silber
    Color(0xFFFFD700), // Gold
    Color(0xFF4ABEF0), // Platin
    Color(0xFF9B59B6), // Diamant
  ];

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
    final d = await ApiService.getLeaderboard(widget.userId);
    setState(() { _data = d; _loading = false; });
  }

  Future<void> _claimReward() async {
    setState(() => _claiming = true);
    final res = await ApiService.claimLeagueReward(widget.userId);
    setState(() => _claiming = false);
    if (!mounted) return;
    if (res['ok'] == true) {
      final coins = res['data']['coins'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$coins Münzen erhalten! 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['data']['fehler'] ?? 'Fehler'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _sendFriendRequest(int toUserId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Freundschaftsanfrage',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text('Anfrage an $name senden?',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Senden', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed || !mounted) return;
    final res = await ApiService.sendFriendRequest(widget.userId, toUserId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['ok'] == true
          ? 'Anfrage an $name gesendet!'
          : (res['data']?['fehler'] ?? 'Fehler')),
      backgroundColor: res['ok'] == true ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final liga = _data?['liga'] as Map<String, dynamic>?;
    final ligaIndex = liga?['index'] as int? ?? 0;
    final ligaColor = _ligaColors[ligaIndex.clamp(0, 4)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rangliste'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Liga'),
            Tab(text: 'Global'),
            Tab(text: 'Freunde'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildLigaTab(ligaColor),
                _buildGlobalTab(),
                _buildRankedList(_data?['freunde'] ?? [], null, showAdd: false),
              ],
            ),
    );
  }

  // ── Liga Tab ──────────────────────────────────────────
  Widget _buildLigaTab(Color ligaColor) {
    final liga = _data?['liga'] as Map<String, dynamic>?;
    if (liga == null) {
      return const Center(child: Text('Keine Daten', style: TextStyle(color: AppColors.textMuted)));
    }

    final members      = liga['members'] as List<dynamic>? ?? [];
    final myRank       = liga['myRank'] as int? ?? 0;
    final kannBelohnen = liga['kannBelohnen'] as bool? ?? false;
    final belohnung    = liga['belohnungCoins'] as int? ?? 0;
    final ligaName     = liga['name'] as String? ?? '';
    final ligaEmoji    = liga['emoji'] as String? ?? '';
    final ligaColor    = _ligaColors[(liga['index'] as int? ?? 0).clamp(0, 4)];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LigaBadge(name: ligaName, emoji: ligaEmoji, color: ligaColor, myRank: myRank)
              .animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
          const SizedBox(height: 12),
          if (myRank >= 1 && myRank <= 3) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: kannBelohnen
                  ? _RewardBanner(
                      key: const ValueKey('claim'),
                      rank: myRank, coins: belohnung,
                      claiming: _claiming, onClaim: _claimReward)
                  : Container(
                      key: const ValueKey('claimed'),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 10),
                        Text('Belohnung diese Woche bereits abgeholt',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ]),
                    ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
          ],
          ...List.generate(members.length, (i) {
            final u    = members[i];
            final isMe = u['isMe'] == true || u['userId'] == widget.userId;
            return _LeaderRow(
              pos:    i + 1,
              name:   u['name'] ?? '',
              xp:     u['xp'] as int? ?? 0,
              streak: u['streakDays'] as int? ?? 0,
              isMe:   isMe,
              accentColor: ligaColor,
              onAdd: isMe ? null : () => _sendFriendRequest(
                  u['userId'] as int, u['name'] as String? ?? ''),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 80 + i * 50))
              .slideX(begin: 0.05);
          }),
        ],
      ),
    );
  }

  // ── Global Tab ────────────────────────────────────────
  Widget _buildGlobalTab() {
    final global        = _data?['global'] as List<dynamic>? ?? [];
    final globalContext = _data?['globalContext'] as List<dynamic>?;
    final meinRang      = _data?['meinRang'] as int?;

    if (global.isEmpty && (globalContext == null || globalContext.isEmpty)) {
      return const Center(
          child: Text('Noch keine Einträge', style: TextStyle(color: AppColors.textMuted)));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (meinRang != null && meinRang > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text('Dein Rang: #$meinRang',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ).animate().fadeIn(duration: 350.ms),

          // Top-100 Liste
          ...List.generate(global.length, (i) {
            final u    = global[i];
            final isMe = u['isMe'] == true || u['userId'] == widget.userId;
            final pos  = u['rang'] as int? ?? (i + 1);
            return _LeaderRow(
              pos:    pos,
              name:   u['name'] ?? '',
              xp:     u['xp'] as int? ?? 0,
              streak: u['streakDays'] as int? ?? 0,
              isMe:   isMe,
              onAdd:  isMe ? null : () => _sendFriendRequest(
                  u['userId'] as int, u['name'] as String? ?? ''),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 40 + i * 30))
              .slideX(begin: 0.05);
          }),

          // Separator + Kontext wenn nicht in Top 100
          if (globalContext != null && globalContext.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('•••',
                      style: TextStyle(
                          color: AppColors.textMuted.withOpacity(0.6),
                          fontSize: 18, letterSpacing: 4)),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ]),
            ).animate().fadeIn(delay: 200.ms),
            ...globalContext.map((u) {
              final isMe = u['isMe'] == true || u['userId'] == widget.userId;
              final pos  = u['rang'] as int? ?? 0;
              return _LeaderRow(
                pos:    pos,
                name:   u['name'] ?? '',
                xp:     u['xp'] as int? ?? 0,
                streak: u['streakDays'] as int? ?? 0,
                isMe:   isMe,
                onAdd:  isMe ? null : () => _sendFriendRequest(
                    u['userId'] as int, u['name'] as String? ?? ''),
              ).animate().fadeIn(delay: 250.ms);
            }),
          ],
        ],
      ),
    );
  }

  // ── Freunde Tab ───────────────────────────────────────
  Widget _buildRankedList(List<dynamic> users, int? meinRang,
      {bool showAdd = true}) {
    if (users.isEmpty) {
      return const Center(
          child: Text('Noch keine Einträge',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (meinRang != null && meinRang > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text('Dein Rang: #$meinRang',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ).animate().fadeIn(duration: 350.ms),
          ...List.generate(users.length, (i) {
            final u    = users[i];
            final isMe = u['isMe'] == true || u['userId'] == widget.userId;
            return _LeaderRow(
              pos:    i + 1,
              name:   u['name'] ?? '',
              xp:     u['xp'] as int? ?? 0,
              streak: u['streakDays'] as int? ?? 0,
              isMe:   isMe,
              onAdd:  (showAdd && !isMe) ? () => _sendFriendRequest(
                  u['userId'] as int, u['name'] as String? ?? '') : null,
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 60 + i * 40))
              .slideX(begin: 0.05);
          }),
        ],
      ),
    );
  }
}

// ── Liga Badge ────────────────────────────────────────
class _LigaBadge extends StatelessWidget {
  final String name;
  final String emoji;
  final Color  color;
  final int    myRank;

  const _LigaBadge({
    required this.name, required this.emoji,
    required this.color, required this.myRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('Liga · Platz $myRank von 12',
              style: TextStyle(color: color.withOpacity(0.75), fontSize: 13)),
        ])),
      ]),
    );
  }
}

// ── Reward Banner ─────────────────────────────────────
class _RewardBanner extends StatelessWidget {
  final int rank;
  final int coins;
  final bool claiming;
  final VoidCallback onClaim;

  const _RewardBanner({
    super.key,
    required this.rank, required this.coins,
    required this.claiming, required this.onClaim,
  });

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final medal = _medals[(rank - 1).clamp(0, 2)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.warning.withOpacity(0.18),
          AppColors.warning.withOpacity(0.06),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wochenbelohnung verfügbar!',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 14)),
          Text('Platz $rank → $coins Münzen',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: claiming ? null : onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: claiming
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Abholen', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Leader Row ────────────────────────────────────────
class _LeaderRow extends StatelessWidget {
  final int pos;
  final String name;
  final int xp;
  final int streak;
  final bool isMe;
  final Color? accentColor;
  final VoidCallback? onAdd;

  const _LeaderRow({
    required this.pos, required this.name, required this.xp,
    required this.streak, required this.isMe,
    this.accentColor, this.onAdd,
  });

  static const _podium = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final highlight = isMe ? (accentColor ?? AppColors.primary) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.only(
          left: 14, top: 10, bottom: 10, right: onAdd != null ? 4 : 14),
      decoration: BoxDecoration(
        color: highlight != null
            ? highlight.withOpacity(0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight != null
              ? highlight.withOpacity(0.4)
              : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: pos <= 3
              ? Text(_podium[pos - 1],
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center)
              : Text('#$pos',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                  textAlign: TextAlign.center),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (highlight ?? AppColors.primary).withOpacity(0.15),
          ),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: highlight ?? AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isMe ? (highlight ?? AppColors.primary) : AppColors.text,
                    fontSize: 14),
                overflow: TextOverflow.ellipsis)),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: (highlight ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Du',
                    style: TextStyle(
                        color: highlight ?? AppColors.primary,
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.local_fire_department, color: AppColors.error, size: 12),
            Text(' $streak', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ])),
        Text(_formatXp(xp),
            style: TextStyle(
                color: isMe ? (highlight ?? AppColors.warning) : AppColors.warning,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        if (onAdd != null)
          IconButton(
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.primary, size: 20),
            onPressed: onAdd,
          ),
      ]),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return xp.toString();
  }
}
