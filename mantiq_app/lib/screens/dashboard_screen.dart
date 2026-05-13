import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  List<dynamic> _trees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees() async {
    setState(() => _loading = true);
    final trees = await ApiService.getTrees(widget.userId);
    setState(() { _trees = trees; _loading = false; });
  }

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
    final name = widget.displayName.isNotEmpty
        ? widget.displayName.split(' ').first
        : widget.email.split('@').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hallo, $name! 👋',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.text, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            const Text('Deine Lernbäume',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
        ),
      ]),
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
        );
      },
    );
  }
}

// ── Baum-Karte ───────────────────────────────────────
class _TreeCard extends StatelessWidget {
  final Map<String, dynamic> tree;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TreeCard({required this.tree, required this.onTap, required this.onDelete});

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
  bool _isPdf   = false;
  bool _loading = false;
  String? _status;

  final _titelCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _pdfPath;
  String? _pdfName;

  @override
  void dispose() {
    _titelCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _submit() async {
    final titel = _titelCtrl.text.trim();

    // Manuell: Titel ist Pflicht. PDF: Titel optional (Claude generiert ihn)
    if (!_isPdf && titel.isEmpty) {
      setState(() => _status = 'Bitte einen Titel eingeben.');
      return;
    }

    setState(() { _loading = true; _status = null; });

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
        Row(children: [
          _modeChip('Manuell', !_isPdf, () => setState(() => _isPdf = false)),
          const SizedBox(width: 8),
          _modeChip('Aus PDF', _isPdf,  () => setState(() => _isPdf = true)),
        ]),
        const SizedBox(height: 20),

        // Titel
        TextField(
          controller: _titelCtrl,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: _isPdf ? 'Titel (optional – Claude generiert ihn)' : 'Titel (z.B. Lineare Algebra)',
          ),
        ),
        const SizedBox(height: 12),

        // Manuell: Beschreibung
        if (!_isPdf) ...[
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
                : Text(_isPdf ? 'Aufgaben generieren' : 'Erstellen'),
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
