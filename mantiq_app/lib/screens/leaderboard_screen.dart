import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await ApiService.getLeaderboard(widget.userId);
    setState(() { _data = d; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rangliste'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Global'), Tab(text: 'Freunde')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(_data?['global'] ?? [], _data?['meinRang'] ?? 0),
                _buildList(_data?['freunde'] ?? [], null),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> users, int? meinRang) {
    if (users.isEmpty) {
      return const Center(
        child: Text('Noch keine Einträge', style: TextStyle(color: AppColors.textMuted)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (meinRang != null && meinRang > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text('Dein Rang: #$meinRang',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
          ...List.generate(users.length, (i) {
            final u   = users[i];
            final pos = i + 1;
            final isMine = u['userId'] == widget.userId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.primary.withOpacity(0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMine ? AppColors.primary.withOpacity(0.4) : AppColors.border),
              ),
              child: Row(children: [
                // Platz
                SizedBox(
                  width: 36,
                  child: Text(
                    pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '#$pos',
                    style: TextStyle(
                      fontSize: pos <= 3 ? 20 : 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isMine ? AppColors.primary : AppColors.text,
                    )),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.local_fire_department, color: AppColors.error, size: 13),
                    Text(' ${u['streakDays']} Tage',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ]),
                ])),
                Text('${u['xp']} XP',
                  style: const TextStyle(
                    color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
