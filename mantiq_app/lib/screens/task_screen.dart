import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TaskScreen extends StatefulWidget {
  final int stepId;
  final String stepTitle;
  final int treeId;
  final int userId;

  const TaskScreen({
    super.key, required this.stepId, required this.stepTitle,
    required this.treeId, required this.userId,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<dynamic> _tasks   = [];
  int   _index   = 0;
  int   _richtig = 0;
  bool  _loading = true;
  bool  _answered  = false;
  bool? _lastCorrect;

  // Zustand fuer den aktuellen Aufgabentyp
  Set<int>      _selectedIds   = {};
  int?          _selectedId;
  double        _sliderValue   = 0;
  List<int>     _sortOrder     = [];
  List<dynamic> _shuffledOpts  = []; // fuer SORTING: einmal geshuffelt, nicht bei jedem Build
  int?          _matchFirst;
  String?       _matchFirstSide;
  Map<int, int> _matchedPairs = {}; // optionId -> partnerId
  int?          _fillSelected;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await ApiService.getStepTasks(widget.stepId);
    setState(() {
      _tasks   = tasks;
      _loading = false;
      if (tasks.isNotEmpty) _initTask(0);
    });
  }

  void _initTask(int i) {
    _index       = i;
    _answered    = false;
    _lastCorrect = null;
    _selectedIds   = {};
    _selectedId    = null;
    _sortOrder     = [];
    _matchFirst    = null;
    _matchFirstSide = null;
    _matchedPairs  = {};
    _fillSelected  = null;

    final task = _tasks[i];
    if (task['type'] == 'NUMBER_LINE') {
      _sliderValue = ((task['numberMin'] as num) + (task['numberMax'] as num)) / 2;
    }
    if (task['type'] == 'SORTING') {
      _shuffledOpts = List.from(task['options'])..shuffle();
    }
  }

  void _nextTask() {
    if (_index + 1 >= _tasks.length) {
      _showCompletion();
    } else {
      setState(() => _initTask(_index + 1));
    }
  }

  Future<void> _showCompletion() async {
    await ApiService.completeStep(widget.stepId, widget.userId);
    if (!mounted) return;
    setState(() => _loading = false); // zeigt Completion-Screen
    _index = _tasks.length; // Signal fuer Completion
  }

  double get _progress => _tasks.isEmpty ? 0 : _index / _tasks.length;

  // ── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    if (_index >= _tasks.length) return _buildCompletion();

    final task = _tasks[_index];

    return Scaffold(
      body: SafeArea(child: Column(children: [

        // Topbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: AppColors.textMuted, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppColors.surface2,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            )),
            const SizedBox(width: 12),
            Text('${_index + 1} / ${_tasks.length}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
        ),

        // Aufgabe
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Frage (bei FILL_BLANK entfällt sie – die Frage steckt schon im Lückentext)
            if (task['type'] != 'FILL_BLANK') ...[
              Text(task['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.4),
              ).animate().fadeIn(),
              const SizedBox(height: 28),
            ],

            // Aufgabentyp
            _buildTaskType(task),

            // Feedback
            if (_answered) _buildFeedback(),
          ]),
        )),

        // Footer
        _buildFooter(task),

      ])),
    );
  }

  // ── Aufgabentypen ─────────────────────────────────

  Widget _buildTaskType(Map<String, dynamic> task) {
    switch (task['type']) {
      case 'SINGLE_CHOICE':   return _buildSingle(task);
      case 'MULTIPLE_CHOICE': return _buildMultiple(task);
      case 'TRUE_FALSE':      return _buildTrueFalse(task);
      case 'NUMBER_LINE':     return _buildNumberLine(task);
      case 'SORTING':         return _buildSorting(task);
      case 'MATCHING':        return _buildMatching(task);
      case 'FILL_BLANK':      return _buildFillBlank(task);
      default: return Text('Unbekannter Typ: ${task['type']}',
                  style: const TextStyle(color: AppColors.textMuted));
    }
  }

  // SINGLE CHOICE
  Widget _buildSingle(Map<String, dynamic> task) {
    final opts = task['options'] as List;
    final buchst = ['A','B','C','D'];
    return Column(children: List.generate(opts.length, (i) {
      final opt = opts[i];
      final id  = opt['id'] as int;
      final selected  = _selectedId == id;
      final isCorrect = opt['correct'] as bool;
      Color borderColor = AppColors.border;
      Color bgColor     = AppColors.surface;
      if (_answered) {
        if (isCorrect)               { borderColor = AppColors.success; bgColor = const Color(0x2034D399); }
        else if (selected && !isCorrect) { borderColor = AppColors.error; bgColor = const Color(0x20F87171); }
      } else if (selected) {
        borderColor = AppColors.primary; bgColor = const Color(0x207C6AF5);
      }
      return GestureDetector(
        onTap: _answered ? null : () => setState(() => _selectedId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(children: [
            _badge(buchst[i % 4], selected && !_answered),
            const SizedBox(width: 12),
            Expanded(child: Text(opt['text'], style: const TextStyle(fontSize: 15, color: AppColors.text))),
          ]),
        ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05),
      );
    }));
  }

  // MULTIPLE CHOICE
  Widget _buildMultiple(Map<String, dynamic> task) {
    final opts = task['options'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mehrere Antworten möglich',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 12),
        ...List.generate(opts.length, (i) {
          final opt = opts[i];
          final id  = opt['id'] as int;
          final selected  = _selectedIds.contains(id);
          final isCorrect = opt['correct'] as bool;
          Color borderColor = selected ? AppColors.primary : AppColors.border;
          Color bgColor     = selected ? const Color(0x207C6AF5) : AppColors.surface;
          if (_answered) {
            if (isCorrect)               { borderColor = AppColors.success; bgColor = const Color(0x2034D399); }
            else if (selected && !isCorrect) { borderColor = AppColors.error; bgColor = const Color(0x20F87171); }
          }
          return GestureDetector(
            onTap: _answered ? null : () => setState(() {
              if (_selectedIds.contains(id)) _selectedIds.remove(id);
              else _selectedIds.add(id);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 2)),
              child: Row(children: [
                Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(opt['text'], style: const TextStyle(fontSize: 15, color: AppColors.text))),
              ]),
            ).animate(delay: (i * 50).ms).fadeIn(),
          );
        }),
      ],
    );
  }

  // TRUE / FALSE
  Widget _buildTrueFalse(Map<String, dynamic> task) {
    final opts = task['options'] as List;
    final richtigeOpt = opts.firstWhere((o) => o['correct'] == true, orElse: () => opts[0]);
    final richtigText = richtigeOpt['text'] as String;

    return Row(children: ['Wahr', 'Falsch'].map((label) {
      final selected = _selectedId != null &&
          ((label == 'Wahr'  && richtigText == 'Wahr'  && _selectedId == 1) ||
           (label == 'Falsch' && richtigText == 'Falsch' && _selectedId == 0) ||
           (_selectedId == label.hashCode));
      final isThisCorrect = label == richtigText;
      Color borderColor = AppColors.border;
      Color bgColor     = AppColors.surface;
      if (_selectedId == label.hashCode) { borderColor = AppColors.primary; bgColor = const Color(0x207C6AF5); }
      if (_answered && isThisCorrect)    { borderColor = AppColors.success; bgColor = const Color(0x2034D399); }
      if (_answered && !isThisCorrect && _selectedId == label.hashCode) { borderColor = AppColors.error; bgColor = const Color(0x20F87171); }

      return Expanded(
        child: GestureDetector(
          onTap: _answered ? null : () {
            setState(() => _selectedId = label.hashCode);
            final richtig = label == richtigText;
            if (richtig) _richtig++;
            setState(() { _answered = true; _lastCorrect = richtig; });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 2)),
            child: Column(children: [
              Text(label == 'Wahr' ? '✓' : '✗', style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            ]),
          ),
        ),
      );
    }).toList());
  }

  // NUMBER LINE
  Widget _buildNumberLine(Map<String, dynamic> task) {
    final min     = (task['numberMin'] as num).toDouble();
    final max     = (task['numberMax'] as num).toDouble();
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$min', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Text('$max', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withOpacity(.2),
          trackHeight: 6,
        ),
        child: Slider(
          value: _sliderValue.clamp(min, max),
          min: min, max: max,
          onChanged: _answered ? null : (v) => setState(() => _sliderValue = v),
        ),
      ),
      Text(_sliderValue.toStringAsFixed(2),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
    ]);
  }

  // SORTING
  Widget _buildSorting(Map<String, dynamic> task) {
    final opts = _shuffledOpts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Klicke die Elemente in der richtigen Reihenfolge.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 12),
        ...opts.map((opt) {
          final id  = opt['id'] as int;
          final pos = _sortOrder.indexOf(id);
          final placed = pos != -1;
          final correctPos = opt['position'] as int?;
          Color borderColor = placed ? AppColors.primary : AppColors.border;
          Color bgColor     = placed ? const Color(0x207C6AF5) : AppColors.surface;
          if (_answered && correctPos != null) {
            final ok = _sortOrder.length > correctPos && _sortOrder[correctPos] == id;
            borderColor = ok ? AppColors.success : AppColors.error;
            bgColor     = ok ? const Color(0x2034D399) : const Color(0x20F87171);
          }
          return GestureDetector(
            onTap: (_answered || placed) ? null : () => setState(() => _sortOrder.add(id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 2)),
              child: Row(children: [
                _badge(placed ? '${pos+1}' : '?', placed),
                const SizedBox(width: 12),
                Expanded(child: Text(opt['text'], style: const TextStyle(fontSize: 15, color: AppColors.text))),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // MATCHING
  Widget _buildMatching(Map<String, dynamic> task) {
    final opts   = task['options'] as List;
    final gruppen = opts.map((o) => o['matchGroup'] as int).toSet().toList();
    final links  = gruppen.map((g) => opts.firstWhere((o) => o['matchGroup'] == g)).toList();
    final rechts = gruppen.map((g) => opts.where((o) => o['matchGroup'] == g).toList()[1]).toList()..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verbinde zusammengehörende Begriffe.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linke Spalte
            Expanded(child: Column(children: links.map((opt) {
              final id = opt['id'] as int;
              final isSelected = _matchFirst == id && _matchFirstSide == 'links';
              final isMatched  = _matchedPairs.containsKey(id);
              return _matchItem(opt['text'], id, 'links', isSelected, isMatched);
            }).toList())),
            const SizedBox(width: 10),
            // Rechte Spalte
            Expanded(child: Column(children: rechts.map((opt) {
              final id = opt['id'] as int;
              final isSelected = _matchFirst == id && _matchFirstSide == 'rechts';
              final isMatched  = _matchedPairs.values.contains(id);
              return _matchItem(opt['text'], id, 'rechts', isSelected, isMatched);
            }).toList())),
          ],
        ),
      ],
    );
  }

  Widget _matchItem(String text, int id, String side, bool selected, bool matched) {
    Color borderColor = matched ? AppColors.success : (selected ? AppColors.primary : AppColors.border);
    Color bgColor     = matched ? const Color(0x2034D399) : (selected ? const Color(0x207C6AF5) : AppColors.surface);

    return GestureDetector(
      onTap: (matched || _answered) ? null : () => _onMatchTap(id, side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 2)),
        child: Center(child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.text))),
      ),
    );
  }

  void _onMatchTap(int id, String side) {
    if (_matchFirst == null) {
      setState(() { _matchFirst = id; _matchFirstSide = side; });
      return;
    }
    if (_matchFirstSide == side) {
      setState(() { _matchFirst = id; _matchFirstSide = side; });
      return;
    }
    // Paar prüfen: beide müssen die gleiche matchGroup haben
    final task = _tasks[_index];
    final opts  = task['options'] as List;
    final opt1  = opts.firstWhere((o) => o['id'] == _matchFirst);
    final opt2  = opts.firstWhere((o) => o['id'] == id);
    if (opt1['matchGroup'] == opt2['matchGroup']) {
      setState(() {
        _matchedPairs[_matchFirst!] = id;
        _matchFirst    = null;
        _matchFirstSide = null;
      });
      // Alle verbunden?
      final gruppen = opts.map((o) => o['matchGroup'] as int).toSet().length;
      if (_matchedPairs.length == gruppen) {
        _richtig++;
        setState(() { _answered = true; _lastCorrect = true; });
      }
    } else {
      // Falsch – kurz rot leuchten
      setState(() { _matchFirst = null; _matchFirstSide = null; });
    }
  }

  // FILL BLANK
  Widget _buildFillBlank(Map<String, dynamic> task) {
    final opts    = (task['options'] as List).toList()..shuffle();
    final korrekt = (task['options'] as List).firstWhere((o) => o['correct'] == true, orElse: () => null);
    final filled  = _fillSelected != null
        ? opts.firstWhere((o) => o['id'] == _fillSelected, orElse: () => null)
        : null;

    final questionText = task['question'] as String;
    final teile = questionText.split('___');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Frage mit Lücke
      RichText(text: TextSpan(
        style: const TextStyle(fontSize: 18, color: AppColors.text, height: 1.6),
        children: [
          TextSpan(text: teile[0]),
          WidgetSpan(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: _answered
                    ? (korrekt != null && _fillSelected == korrekt['id'] ? AppColors.success : AppColors.error)
                    : AppColors.primary,
                width: 2,
              )),
            ),
            child: Text(
              filled != null ? filled['text'] : '___',
              style: TextStyle(
                color: _answered
                    ? (korrekt != null && _fillSelected == korrekt['id'] ? AppColors.success : AppColors.error)
                    : AppColors.primary,
                fontWeight: FontWeight.w700, fontSize: 18,
              ),
            ),
          )),
          if (teile.length > 1) TextSpan(text: teile[1]),
        ],
      )),
      const SizedBox(height: 24),
      // Wörter
      Wrap(spacing: 8, runSpacing: 8, children: opts.map((opt) {
        final id = opt['id'] as int;
        final selected  = _fillSelected == id;
        final isCorrect = opt['correct'] as bool;
        Color borderColor = selected ? AppColors.primary : AppColors.border;
        Color bgColor     = selected ? const Color(0x207C6AF5) : AppColors.surface;
        if (_answered && isCorrect)               { borderColor = AppColors.success; bgColor = const Color(0x2034D399); }
        if (_answered && selected && !isCorrect)  { borderColor = AppColors.error;   bgColor = const Color(0x20F87171); }
        return GestureDetector(
          onTap: (_answered) ? null : () => setState(() => _fillSelected = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(99), border: Border.all(color: borderColor)),
            child: Text(opt['text'], style: const TextStyle(fontSize: 14, color: AppColors.text)),
          ),
        );
      }).toList()),
    ]);
  }

  // ── Feedback ──────────────────────────────────────
  Widget _buildFeedback() {
    final richtig = _lastCorrect ?? false;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: richtig ? const Color(0x2034D399) : const Color(0x20F87171),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: richtig ? AppColors.success : AppColors.error),
      ),
      child: Row(children: [
        Text(richtig ? '✓' : '✗',
          style: TextStyle(fontSize: 18, color: richtig ? AppColors.success : AppColors.error)),
        const SizedBox(width: 10),
        Text(richtig ? 'Richtig!' : 'Falsch.',
          style: TextStyle(color: richtig ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700)),
      ]),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  // ── Footer ────────────────────────────────────────
  Widget _buildFooter(Map<String, dynamic> task) {
    final canCheck = _canCheck(task);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.surface,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canCheck ? (_answered ? _nextTask : () => _check(task)) : null,
          child: Text(_answered ? 'Weiter →' : 'Überprüfen'),
        ),
      ),
    );
  }

  bool _canCheck(Map<String, dynamic> task) {
    if (_answered) return true;
    switch (task['type']) {
      case 'SINGLE_CHOICE':   return _selectedId != null;
      case 'MULTIPLE_CHOICE': return _selectedIds.isNotEmpty;
      case 'TRUE_FALSE':      return false; // Direkt beim Antippen
      case 'NUMBER_LINE':     return true;
      case 'SORTING':
        final opts = task['options'] as List;
        return _sortOrder.length == opts.length;
      case 'MATCHING':        return false; // Automatisch wenn alle verbunden
      case 'FILL_BLANK':      return _fillSelected != null;
      default: return false;
    }
  }

  void _check(Map<String, dynamic> task) {
    bool richtig = false;
    switch (task['type']) {
      case 'SINGLE_CHOICE':
        richtig = (task['options'] as List)
            .any((o) => o['id'] == _selectedId && o['correct'] == true);
        break;
      case 'MULTIPLE_CHOICE':
        final opts = task['options'] as List;
        final alleRichtig = opts.where((o) => o['correct'] == true).map((o) => o['id'] as int).toSet();
        richtig = _selectedIds.length == alleRichtig.length &&
                  _selectedIds.every((id) => alleRichtig.contains(id));
        break;
      case 'NUMBER_LINE':
        final min     = (task['numberMin'] as num).toDouble();
        final max     = (task['numberMax'] as num).toDouble();
        final korrekt = (task['numberCorrect'] as num).toDouble();
        final tol     = (max - min) * 0.05;
        richtig = (_sliderValue - korrekt).abs() <= tol;
        break;
      case 'SORTING':
        final opts = (task['options'] as List)
            .toList()..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
        final korrekt = opts.map((o) => o['id'] as int).toList();
        richtig = _sortOrder.toString() == korrekt.toString();
        break;
      case 'FILL_BLANK':
        richtig = (task['options'] as List)
            .any((o) => o['id'] == _fillSelected && o['correct'] == true);
        break;
    }
    if (richtig) _richtig++;
    setState(() { _answered = true; _lastCorrect = richtig; });
  }

  // ── Completion Screen ─────────────────────────────
  Widget _buildCompletion() {
    final prozent = _tasks.isEmpty ? 0 : (_richtig / _tasks.length * 100).round();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(prozent >= 70 ? '🎉' : '📚',
                  style: const TextStyle(fontSize: 72),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text(prozent >= 70 ? 'Super gemacht!' : 'Weiter üben!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(prozent >= 70 ? 'Schritt abgeschlossen.' : 'Nicht aufgeben!',
                  style: const TextStyle(color: AppColors.textMuted),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _stat('$_richtig', 'Richtig'),
                  const SizedBox(width: 32),
                  _stat('${_tasks.length - _richtig}', 'Falsch'),
                  const SizedBox(width: 32),
                  _stat('$prozent%', 'Punkte'),
                ]).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← Zurück zum Baum'),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
      Text(label,  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
    ]);
  }

  Widget _badge(String label, bool active) {
    return Container(
      width: 28, height: 28, decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.surface2,
      ),
      child: Center(child: Text(label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted))),
    );
  }
}
