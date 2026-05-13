import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'task_screen.dart';

class TreeScreen extends StatefulWidget {
  final int treeId;
  final int userId;
  const TreeScreen({super.key, required this.treeId, required this.userId});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  Map<String, dynamic>? _tree;
  bool _loading  = true;
  bool _editMode = false; // Edit-Modus: Reorder + Rename

  final List<String> _icons = ['📘','🔢','⚗️','🧬','💡','🧩','📐','🔭','🧮','🎯','🔬','🌐'];

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() => _loading = true);
    final tree = await ApiService.getTree(widget.treeId, widget.userId);
    setState(() { _tree = tree; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final steps = _tree?['steps'] as List<dynamic>? ?? [];
    final completedCount = steps.where((s) => s['completed'] as bool).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tree?['title']?.isNotEmpty == true ? _tree!['title'] : 'Lernbaum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_tree != null)
            TextButton(
              onPressed: () => setState(() => _editMode = !_editMode),
              child: Text(
                _editMode ? 'Fertig' : 'Bearbeiten',
                style: TextStyle(
                  color: _editMode ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: (_tree != null && steps.isNotEmpty)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: steps.isEmpty ? 0 : completedCount / steps.length,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 4,
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tree == null
              ? const Center(child: Text('Baum nicht gefunden',
                  style: TextStyle(color: AppColors.textMuted)))
              : _editMode
                  ? _buildEditMode()
                  : _buildPath(),
      floatingActionButton: _tree == null ? null : FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddStepDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Edit-Modus: Reorder + Rename + Delete ───────────
  Widget _buildEditMode() {
    final steps = List<dynamic>.from(_tree!['steps'] as List);
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: steps.length,
      onReorder: (oldIdx, newIdx) async {
        if (newIdx > oldIdx) newIdx--;
        final moved = steps.removeAt(oldIdx);
        steps.insert(newIdx, moved);

        // Neue Reihenfolge sofort im UI zeigen
        setState(() {
          (_tree!['steps'] as List).clear();
          (_tree!['steps'] as List).addAll(steps);
        });

        // Backend aktualisieren
        final order = steps.asMap().entries
            .map((e) => {'id': e.value['id'] as int, 'position': e.key})
            .toList();
        await ApiService.reorderSteps(widget.treeId, order);
      },
      itemBuilder: (context, i) {
        final step = steps[i];
        return Container(
          key: ValueKey(step['id']),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(step['title'] ?? '',
                style: const TextStyle(color: AppColors.text, fontSize: 15))),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              onPressed: () => _renameDialog(step['id'], step['title'] ?? ''),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
              onPressed: () => _confirmDeleteStep(step['id'], step['title'] ?? ''),
            ),
          ]),
        );
      },
    );
  }

  void _renameDialog(int stepId, String currentTitle) {
    final ctrl = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Schritt umbenennen', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Neuer Titel'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              final titel = ctrl.text.trim();
              if (titel.isEmpty) return;
              Navigator.pop(ctx);
              await ApiService.renameStep(stepId, titel);
              _loadTree();
            },
            child: const Text('Speichern', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _openAddStepDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Schritt hinzufügen', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Titel des Schritts'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final titel = ctrl.text.trim();
              if (titel.isEmpty) return;
              Navigator.pop(ctx);
              final res = await ApiService.addStep(widget.treeId, titel);
              if (res['ok']) _loadTree();
            },
            child: const Text('Hinzufügen', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _stepContextMenu(int stepId, String stepTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: const Text('Umbenennen', style: TextStyle(color: AppColors.text)),
            onTap: () { Navigator.pop(ctx); _renameDialog(stepId, stepTitle); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Löschen', style: TextStyle(color: AppColors.error)),
            onTap: () { Navigator.pop(ctx); _confirmDeleteStep(stepId, stepTitle); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmDeleteStep(int stepId, String stepTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Schritt löschen?', style: TextStyle(color: AppColors.text)),
        content: Text('„$stepTitle" und alle Aufgaben darin werden gelöscht.',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deleteStep(stepId);
              _loadTree();
            },
            child: const Text('Löschen', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPath() {
    final steps = _tree!['steps'] as List<dynamic>;
    if (steps.isEmpty) {
      return const Center(
          child: Text('Noch keine Schritte vorhanden.',
              style: TextStyle(color: AppColors.textMuted)));
    }

    final ersterAktiv = steps.indexWhere((s) => !(s['completed'] as bool));
    final completedCount = steps.where((s) => s['completed'] as bool).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadTree,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w   = constraints.maxWidth;
            // Node-Mittelpunkte (x-Position): links und rechts wechselnd
            final leftX  = w * 0.28;
            final rightX = w * 0.72;

            final List<Widget> children = [];

            // Fortschritts-Header
            children.add(_buildProgressHeader(completedCount, steps.length));

            for (int i = 0; i < steps.length; i++) {
              final step      = steps[i];
              final completed = step['completed'] as bool;
              final isActive  = i == ersterAktiv;
              final isLocked  = !completed && !isActive;
              final isLeft    = i % 2 == 0;
              final nodeX     = isLeft ? leftX : rightX;

              // Verbindungskurve zum vorherigen Node
              if (i > 0) {
                final prevLeft      = (i - 1) % 2 == 0;
                final prevX         = prevLeft ? leftX : rightX;
                final prevCompleted = steps[i - 1]['completed'] as bool;
                children.add(_buildConnector(prevX, nodeX, prevCompleted));
              }

              // Abschnitts-Trenner alle 3 Schritte (nach der Linie, vor dem Node)
              if (i > 0 && i % 3 == 0) {
                children.add(_buildSectionDivider(i ~/ 3));
              }

              // Schritt-Node
              children.add(
                Padding(
                  padding: EdgeInsets.only(
                    left:  isLeft  ? leftX  - 55 : 0,
                    right: !isLeft ? w - rightX - 55 : 0,
                  ),
                  child: Align(
                    alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                    child: _StepNode(
                      label:     step['title'] ?? '',
                      icon:      completed ? '✓' : _icons[i % _icons.length],
                      number:    i + 1,
                      completed: completed,
                      active:    isActive,
                      locked:    isLocked,
                      onTap: isLocked
                          ? null
                          : () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => TaskScreen(
                                  stepId:    step['id'],
                                  stepTitle: step['title'],
                                  treeId:    widget.treeId,
                                  userId:    widget.userId,
                                ),
                              ));
                              _loadTree();
                            },
                      onLongPress: () => _stepContextMenu(step['id'], step['title'] ?? ''),
                    ).animate(delay: (i * 60).ms).fadeIn().scale(begin: const Offset(0.85, 0.85)),
                  ),
                ),
              );
            }

            // Abschluss-Banner
            if (steps.every((s) => s['completed'] as bool)) {
              children.addAll([
                const SizedBox(height: 40),
                Center(
                  child: Column(children: [
                    const Text('🏆', style: TextStyle(fontSize: 64))
                        .animate().scale(duration: 400.ms).then().shimmer(),
                    const SizedBox(height: 12),
                    const Text('Alles abgeschlossen!',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: AppColors.success))
                        .animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 6),
                    Text('${steps.length} von ${steps.length} Schritten',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14))
                        .animate().fadeIn(delay: 350.ms),
                  ]),
                ),
              ]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          },
        ),
      ),
    );
  }

  // ── Fortschritts-Header ──────────────────────────────
  Widget _buildProgressHeader(int done, int total) {
    final pct = total == 0 ? 0 : (done / total * 100).round();
    final title = _tree?['title'] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.text, letterSpacing: -0.5,
              )),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text('$done / $total Schritte abgeschlossen  ·  $pct%',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Abschnitts-Trenner ───────────────────────────────
  Widget _buildSectionDivider(int section) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 28),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.border.withOpacity(0.4), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Abschnitt $section',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border.withOpacity(0.4), thickness: 1)),
      ]),
    );
  }

  // ── Bezier-Verbindung zwischen zwei Nodes ────────────
  Widget _buildConnector(double fromX, double toX, bool completed) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(fromX: fromX, toX: toX, completed: completed),
      ),
    );
  }
}

// ── Bezier-Pfad Painter ──────────────────────────────
class _ConnectorPainter extends CustomPainter {
  final double fromX;
  final double toX;
  final bool completed;

  const _ConnectorPainter({
    required this.fromX, required this.toX, required this.completed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = completed
          ? AppColors.success.withOpacity(0.65)
          : AppColors.border.withOpacity(0.55)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(fromX, 0)
      ..cubicTo(
        fromX, size.height * 0.45,
        toX,   size.height * 0.55,
        toX,   size.height,
      );

    if (completed) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 9.0;
    const gap  = 6.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.fromX != fromX || old.toX != toX || old.completed != completed;
}

// ── Schritt-Node Widget ──────────────────────────────
class _StepNode extends StatelessWidget {
  final String label;
  final String icon;
  final int    number;
  final bool completed;
  final bool active;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _StepNode({
    required this.label, required this.icon, required this.number,
    required this.completed, required this.active,
    required this.locked, this.onTap, this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor     = AppColors.surface;
    Color textColor   = AppColors.textMuted.withOpacity(0.45);

    if (completed) {
      borderColor = AppColors.success;
      bgColor     = const Color(0x2034D399);
      textColor   = AppColors.text;
    } else if (active) {
      borderColor = AppColors.primary;
      bgColor     = const Color(0x207C6AF5);
      textColor   = AppColors.text;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nummerierungs-Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: completed
                    ? AppColors.success.withOpacity(0.18)
                    : active
                        ? AppColors.primary.withOpacity(0.18)
                        : AppColors.surface2,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: completed
                        ? AppColors.success
                        : active
                            ? AppColors.primary
                            : AppColors.textMuted.withOpacity(0.4),
                  )),
            ),
            const SizedBox(height: 6),

            // Haupt-Kreis with progress ring
            SizedBox(
              width: 86, height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 86, height: 86,
                    child: CircularProgressIndicator(
                      value: completed ? 1.0 : 0.0,
                      strokeWidth: 4.5,
                      backgroundColor: locked
                          ? Colors.transparent
                          : active
                              ? AppColors.primary.withOpacity(0.28)
                              : AppColors.success.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(
                        completed ? AppColors.success : Colors.transparent,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 74, height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 3),
                      boxShadow: active
                          ? [BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 22, spreadRadius: 4)]
                          : null,
                    ),
                    child: Center(
                      child: locked
                          ? Icon(Icons.lock_rounded, color: AppColors.border.withOpacity(0.5), size: 26)
                          : Text(icon,
                              style: TextStyle(
                                fontSize: completed ? 24 : 28,
                                color: completed ? AppColors.success : null,
                              )),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Label
            Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.35,
              )),
          ],
        ),
      ),
    );
  }
}
