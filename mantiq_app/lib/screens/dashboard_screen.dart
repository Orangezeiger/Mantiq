import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'tree_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int    userId;
  final String email;
  final String displayName;
  const DashboardScreen({
    super.key, required this.userId, required this.email, this.displayName = ''});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _trees   = [];
  bool _loading          = true;
  int  _coins            = 0;
  int  _streakDays       = 0;
  String _firstName      = '';
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshStats());
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    final user = await ApiService.getUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _coins      = user?['coins']      as int? ?? _coins;
      _streakDays = user?['streakDays'] as int? ?? _streakDays;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getTrees(widget.userId),
      ApiService.getUser(widget.userId),
    ]);
    final trees = results[0] as List<dynamic>;
    final user  = results[1] as Map<String, dynamic>?;
    setState(() {
      _trees      = trees;
      _coins      = user?['coins']      as int? ?? 0;
      _streakDays = user?['streakDays'] as int? ?? 0;
      _firstName  = user?['firstName']  as String? ?? '';
      _loading    = false;
    });
  }

  Future<void> _loadTrees() => _load();

  // ── Neuer Baum Modal ────────────────────────────────
  void _openNewTreeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NewTreeSheet(userId: widget.userId, onCreated: _loadTrees),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mantiq',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24,
              color: AppColors.primary, letterSpacing: -1)),
        actions: [
          Row(children: [
            Text('🔥', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 3),
            Text('$_streakDays',
              style: const TextStyle(
                color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            Text('🪙', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 3),
            Text('$_coins',
              style: const TextStyle(
                color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
          ]),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadTrees,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _trees.isEmpty
                ? _emptyState()
                : _treeList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTreeModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Neuer Baum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Noch keine Lernbäume',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Erstelle deinen ersten Baum',
            style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openNewTreeModal,
            icon: const Icon(Icons.add),
            label: const Text('Jetzt starten'),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final name = _firstName.isNotEmpty ? _firstName : widget.email.split('@').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hallo, $name! 👋',
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.text, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        const Text('Deine Lernbäume',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
    );
  }

  Widget _statChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _editTree(Map<String, dynamic> tree) {
    final titleCtrl = TextEditingController(text: tree['title'] ?? '');
    final descCtrl  = TextEditingController(text: tree['description'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Baum bearbeiten', style: TextStyle(color: AppColors.text)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: titleCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Titel'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Beschreibung (optional)'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              await ApiService.updateTree(tree['id'] as int, title, descCtrl.text.trim());
              _loadTrees();
            },
            child: const Text('Speichern', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _treeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trees.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildGreeting();
        final tree = _trees[i - 1];
        final treeId = tree['id'] as int;
        return _TreeCard(
          tree: tree,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => TreeScreen(treeId: treeId, userId: widget.userId),
            ));
            _loadTrees();
          },
          onDelete: () async {
            await ApiService.deleteTree(treeId);
            _loadTrees();
          },
          onEdit:  () => _editTree(tree),
          onShare: () => _shareTree(tree),
        );
      },
    );
  }

  void _shareTree(Map<String, dynamic> tree) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ShareSheet(
        tree: tree,
        userId: widget.userId,
        onImported: _loadTrees,
      ),
    );
  }
}

// ── Baum-Karte ───────────────────────────────────────
class _TreeCard extends StatelessWidget {
  final Map<String, dynamic> tree;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _TreeCard({required this.tree, required this.onTap, required this.onDelete, required this.onEdit, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final desc = tree['description'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent title header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(tree['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800,
                        color: AppColors.text, letterSpacing: -0.4,
                      )),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // Description + step count
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: [
                  if (desc.isNotEmpty)
                    Expanded(
                      child: Text(desc,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    )
                  else
                    const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('${tree['stepCount']} Schritte',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Baum löschen?', style: TextStyle(color: AppColors.text)),
      content: Text('„${tree['title']}" wird unwiderruflich gelöscht.',
          style: const TextStyle(color: AppColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted))),
        TextButton(onPressed: () { Navigator.pop(ctx); onDelete(); },
            child: const Text('Löschen', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }
}

// ── Bottom Sheet: Neuer Baum ─────────────────────────
class _NewTreeSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onCreated;
  const _NewTreeSheet({required this.userId, required this.onCreated});

  @override
  State<_NewTreeSheet> createState() => _NewTreeSheetState();
}

class _NewTreeSheetState extends State<_NewTreeSheet> {
  // 0 = Manuell, 1 = Aus PDF, 2 = Per Code, 3 = Aus Datei
  int  _mode    = 0;
  bool _loading = false;
  String? _status;

  final _titelCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _codeCtrl  = TextEditingController();
  String? _pdfPath;
  String? _pdfName;
  String? _mantiqPath;
  String? _mantiqName;

  bool get _isPdf  => _mode == 1;
  bool get _isCode => _mode == 2;
  bool get _isFile => _mode == 3;

  @override
  void dispose() {
    _titelCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfPath = result.files.single.path;
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<void> _pickMantiqFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _mantiqPath = result.files.single.path;
        _mantiqName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _status = null; });

    if (_isCode) {
      final code = _codeCtrl.text.trim().toUpperCase();
      if (code.length != 6) {
        setState(() { _loading = false; _status = 'Bitte einen 6-stelligen Code eingeben.'; });
        return;
      }
      final res = await ApiService.importByCode(code, widget.userId);
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['ok']) {
        widget.onCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('„${res['data']['title']}" importiert ✓'),
          backgroundColor: AppColors.surface2, behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _status = 'Code nicht gefunden.');
      }
      return;
    }

    if (_isFile) {
      if (_mantiqPath == null) {
        setState(() { _loading = false; _status = 'Bitte eine .mantiq-Datei auswählen.'; });
        return;
      }
      final content = await File(_mantiqPath!).readAsString();
      final tree = jsonDecode(content) as Map<String, dynamic>;
      final res  = await ApiService.importFile(widget.userId, tree);
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['ok']) {
        widget.onCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('„${res['data']['title']}" importiert ✓'),
          backgroundColor: AppColors.surface2, behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _status = 'Import fehlgeschlagen.');
      }
      return;
    }

    final titel = _titelCtrl.text.trim();
    if (!_isPdf && titel.isEmpty) {
      setState(() { _loading = false; _status = 'Bitte einen Titel eingeben.'; });
      return;
    }

    if (_isPdf) {
      if (_pdfPath == null) {
        setState(() { _loading = false; _status = 'Bitte eine PDF-Datei auswählen.'; });
        return;
      }
      setState(() => _status = 'Claude analysiert die Folien…');
      final res = await ApiService.uploadPdf(_pdfPath!, widget.userId, titel);
      if (!mounted) return;
      setState(() => _loading = false);

      if (res['ok']) {
        widget.onCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('„${res['data']['titel']}" erstellt mit ${res['data']['schritte']} Schritten ✓'),
          backgroundColor: AppColors.surface2, behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _status = 'Fehler: ${res['data']['fehler'] ?? 'Unbekannt'}');
      }
    } else {
      final res = await ApiService.createTree(widget.userId, titel, _descCtrl.text.trim());
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['ok']) {
        widget.onCreated();
        Navigator.pop(context);
      } else {
        setState(() => _status = res['data']['fehler'] ?? 'Fehler');
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

        // Handle
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        const Text('Neuer Lernbaum',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 20),

        // Modus-Toggle
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _modeChip('Manuell',    _mode == 0, () => setState(() => _mode = 0)),
            const SizedBox(width: 8),
            _modeChip('Aus PDF',    _mode == 1, () => setState(() => _mode = 1)),
            const SizedBox(width: 8),
            _modeChip('Per Code',   _mode == 2, () => setState(() => _mode = 2)),
            const SizedBox(width: 8),
            _modeChip('Aus Datei',  _mode == 3, () => setState(() => _mode = 3)),
          ]),
        ),
        const SizedBox(height: 20),

        // Per Code
        if (_isCode) ...[
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(color: AppColors.text, fontSize: 20,
                fontWeight: FontWeight.w700, letterSpacing: 4),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(hintText: 'ABCD12', counterText: ''),
          ),
          const SizedBox(height: 12),
        ],

        // Aus Datei (.mantiq)
        if (_isFile) ...[
          GestureDetector(
            onTap: _pickMantiqFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _mantiqPath != null ? AppColors.primary : AppColors.border),
              ),
              child: Column(children: [
                Text(_mantiqPath != null ? '📎' : '🌿', style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  _mantiqPath != null ? _mantiqName! : '.mantiq-Datei auswählen',
                  style: TextStyle(
                    color: _mantiqPath != null ? AppColors.primary : AppColors.textMuted,
                    fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Titel (nur Manuell und PDF)
        if (!_isCode && !_isFile) ...[
          TextField(
            controller: _titelCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: _isPdf ? 'Titel (optional – Claude generiert ihn)' : 'Titel (z.B. Lineare Algebra)',
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Manuell: Beschreibung
        if (_mode == 0) ...[
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Beschreibung (optional)'),
          ),
          const SizedBox(height: 12),
        ],

        // PDF: Datei auswählen
        if (_isPdf) ...[
          GestureDetector(
            onTap: _pickPdf,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pdfPath != null ? AppColors.primary : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(children: [
                Text(_pdfPath != null ? '📎' : '📄', style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  _pdfPath != null ? _pdfName! : 'PDF tippen um auszuwählen',
                  style: TextStyle(
                    color: _pdfPath != null ? AppColors.primary : AppColors.textMuted,
                    fontSize: 14, fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Ladebalken + Status beim Generieren
        if (_loading && _isPdf) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(_status ?? 'Lädt…',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
        ] else if (_status != null) ...[
          Text(_status!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          const SizedBox(height: 12),
        ],

        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isCode ? 'Importieren' : _isFile ? 'Importieren' : _isPdf ? 'Aufgaben generieren' : 'Erstellen'),
          ),
        ),

      ]),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
      ),
    );
  }
}

// ── Share-Sheet ──────────────────────────────────────
class _ShareSheet extends StatefulWidget {
  final Map<String, dynamic> tree;
  final int userId;
  final VoidCallback onImported;
  const _ShareSheet({required this.tree, required this.userId, required this.onImported});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool    _loading = false;
  String? _code;
  String? _status;

  Future<void> _generateCode() async {
    setState(() { _loading = true; _status = null; });
    final res = await ApiService.generateShareCode(
        widget.tree['id'] as int, widget.userId);
    setState(() {
      _loading = false;
      _code    = res?['code'] as String?;
      if (_code == null) _status = 'Fehler beim Generieren.';
    });
  }

  Future<void> _exportFile() async {
    setState(() { _loading = true; _status = null; });
    final data = await ApiService.exportTree(widget.tree['id'] as int);
    if (data == null) {
      setState(() { _loading = false; _status = 'Export fehlgeschlagen.'; });
      return;
    }
    final dir  = await getTemporaryDirectory();
    final name = (widget.tree['title'] as String)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '')
        .trim()
        .replaceAll(' ', '_');
    final file = File('${dir.path}/$name.mantiq');
    await file.writeAsString(jsonEncode(data));
    setState(() => _loading = false);
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Mantiq-Baum: ${widget.tree['title']}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('„${widget.tree['title']}" teilen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 20),

        // Optionen
        _shareOption(
          icon: Icons.tag_rounded,
          label: 'Per Code teilen',
          sub: 'Freund gibt den Code in der App ein',
          onTap: _generateCode,
        ),
        const SizedBox(height: 10),
        _shareOption(
          icon: Icons.file_download_outlined,
          label: 'Als .mantiq-Datei exportieren',
          sub: 'Über WhatsApp, Mail o.ä. verschicken',
          onTap: _exportFile,
        ),

        if (_loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ],
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(_status!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        if (_code != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Column(children: [
              const Text('Dein Share-Code', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(_code!,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                      color: AppColors.primary, letterSpacing: 6)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _code!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Code kopiert!'),
                    backgroundColor: AppColors.surface2,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('Kopieren', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _shareOption({required IconData icon, required String label, required String sub, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(sub,   style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.border),
        ]),
      ),
    );
  }
}
