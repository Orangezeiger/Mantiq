import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GroupsScreen extends StatefulWidget {
  final int  userId;
  final bool embedded; // true = wird als Tab in FriendsScreen eingebettet
  const GroupsScreen({super.key, required this.userId, this.embedded = false});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> _myGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final g = await ApiService.getMyGroups(widget.userId);
    setState(() { _myGroups = g; _loading = false; });
  }

  void _showCreateOrJoin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _GroupSheet(userId: widget.userId, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: _myGroups.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    Center(child: Column(children: [
                      Text('🏫', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Noch keiner Gruppe beigetreten',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      SizedBox(height: 6),
                      Text('Erstelle eine oder tritt mit einem Code bei',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ])),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myGroups.length,
                    itemBuilder: (_, i) {
                      final g = _myGroups[i];
                      return _GroupCard(
                        group: g,
                        userId: widget.userId,
                        onLeave: _load,
                      );
                    },
                  ),
          );

    if (widget.embedded) {
      return Stack(children: [
        body,
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            heroTag: 'groups_fab',
            backgroundColor: AppColors.primary,
            onPressed: _showCreateOrJoin,
            child: const Icon(Icons.group_add_rounded, color: Colors.white),
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gruppen')),
      body: body,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showCreateOrJoin,
        child: const Icon(Icons.group_add_rounded, color: Colors.white),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final int                  userId;
  final VoidCallback         onLeave;

  const _GroupCard({required this.group, required this.userId, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(group['groupType'] == 'UNIVERSITY' ? '🏫' : '📚',
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15)),
              Text('${group['memberCount']} Mitglieder · ${group['groupType']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            PopupMenuButton<String>(
              color: AppColors.surface2,
              onSelected: (v) async {
                if (v == 'code') {
                  await Clipboard.setData(ClipboardData(text: group['inviteCode']));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Einladungscode kopiert!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } else if (v == 'leave') {
                  await ApiService.leaveGroup(group['id'], userId);
                  onLeave();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'code',
                    child: Row(children: [
                      const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Code: ${group['inviteCode']}',
                          style: const TextStyle(color: AppColors.text)),
                    ])),
                const PopupMenuItem(value: 'leave',
                    child: Row(children: [
                      Icon(Icons.exit_to_app, size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Verlassen', style: TextStyle(color: AppColors.error)),
                    ])),
              ],
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
            ),
          ]),
        ),

        // Geteilte Bäume
        _GroupTrees(groupId: group['id'], userId: userId),
      ]),
    );
  }
}

class _GroupTrees extends StatefulWidget {
  final int groupId;
  final int userId;
  const _GroupTrees({required this.groupId, required this.userId});

  @override
  State<_GroupTrees> createState() => _GroupTreesState();
}

class _GroupTreesState extends State<_GroupTrees> {
  List<dynamic> _trees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await ApiService.getGroupTrees(widget.groupId);
    if (mounted) setState(() => _trees = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_trees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text('Noch keine Bäume geteilt',
            style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.border, height: 16),
          const Text('Geteilte Bäume',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._trees.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.forest_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(t['title'],
                  style: const TextStyle(color: AppColors.text, fontSize: 13))),
              Text('${t['stepCount']} Schritte',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          )),
        ],
      ),
    );
  }
}

// Bottom Sheet: Gruppe erstellen oder beitreten
class _GroupSheet extends StatefulWidget {
  final int          userId;
  final VoidCallback onDone;
  const _GroupSheet({required this.userId, required this.onDone});

  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  bool   _create  = true;
  bool   _loading = false;
  String _type    = 'MODULE';

  final _nameCtrl   = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _codeCtrl   = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    if (_create) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) { setState(() => _loading = false); return; }
      final res = await ApiService.createGroup(widget.userId, name, _type, _descCtrl.text.trim());
      if (!mounted) return;
      if (res['ok']) { Navigator.pop(context); widget.onDone(); }
    } else {
      final code = _codeCtrl.text.trim().toUpperCase();
      final res  = await ApiService.joinGroup(widget.userId, code);
      if (!mounted) return;
      if (res['ok']) {
        Navigator.pop(context);
        widget.onDone();
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['data']['fehler'] ?? 'Fehler'),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Gruppe', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 16),

        // Toggle
        Row(children: [
          _chip('Erstellen', _create,  () => setState(() => _create = true)),
          const SizedBox(width: 8),
          _chip('Beitreten', !_create, () => setState(() => _create = false)),
        ]),
        const SizedBox(height: 16),

        if (_create) ...[
          // Typ
          Row(children: [
            _chip('Modul 📚', _type == 'MODULE',      () => setState(() => _type = 'MODULE')),
            const SizedBox(width: 8),
            _chip('Uni 🏫',   _type == 'UNIVERSITY',  () => setState(() => _type = 'UNIVERSITY')),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Gruppenname (z.B. Analysis 1)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Beschreibung (optional)'),
          ),
        ] else ...[
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(color: AppColors.text, letterSpacing: 2),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Einladungscode (z.B. A1B2C3D4)'),
          ),
        ],
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_create ? 'Gruppe erstellen' : 'Beitreten'),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : AppColors.textMuted,
          fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}
