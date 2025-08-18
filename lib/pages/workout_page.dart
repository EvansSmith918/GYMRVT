// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/rep_logger.dart';
import 'package:gymrvt/services/workout_stats.dart';
import 'package:gymrvt/services/user_prefs.dart';
import 'package:gymrvt/services/program_templates.dart';
import 'package:gymrvt/services/plate_math.dart';

import 'package:gymrvt/pages/workout_history_page.dart';
import 'package:gymrvt/pages/exercise_insights_page.dart';
import 'package:gymrvt/pages/exercise_library_page.dart';
import 'package:gymrvt/pages/program_templates_page.dart';
import 'package:gymrvt/pages/settings_page.dart';

import 'package:gymrvt/widgets/streak_goal_header.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String _fmtWeight(double display) =>
      '${display == display.truncateToDouble() ? display.toInt() : display.toStringAsFixed(1)} ${_unit == WeightUnit.lb ? 'lb' : 'kg'}';
  String _fmtLoad(double v, NumberFormat fmt) => '${fmt.format(v.round())} lb';

  final _newExerciseCtl = TextEditingController();
  final Map<String, TextEditingController> _repsCtl = {};
  final Map<String, TextEditingController> _weightCtl = {};
  final Map<String, double> _prByName = {};

  DailyWorkout? _day;
  bool _loading = true;

  WeightUnit _unit = WeightUnit.lb;
  int _restDefault = 90;

  Timer? _restTimer;
  int _restRemaining = 0;

  Map<String, double> _suggestedLb = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newExerciseCtl.dispose();
    for (final c in _repsCtl.values) {
      c.dispose();
    }
    for (final c in _weightCtl.values) {
      c.dispose();
    }
    _restTimer?.cancel();
    super.dispose();
  }

  DateTime get _today => DateTime.now();

  Future<void> _load() async {
    final u = await UserPrefs.unit();
    final r = await UserPrefs.restSeconds();
    final d = await WorkoutStore().getDay(_today);
    final sugg = await ProgramTemplates.loadSuggestions(_today);

    if (!mounted) return;
    setState(() {
      _unit = u;
      _restDefault = r;
      _day = d;
      _suggestedLb = sugg;
      _loading = false;
    });

    _prByName.clear();
    for (final ex in d.exercises) {
      final best = await WorkoutStats.bestOneRm(ex.name);
      if (!mounted) return;
      _prByName[ex.name] = best;
    }

    for (final ex in d.exercises) {
      _repsCtl[ex.id] ??= TextEditingController(text: '10');
      final suggLb = _suggestedLb[ex.name];
      final defaultDisplay = suggLb == null
          ? (_unit == WeightUnit.lb ? 135.0 : 60.0)
          : UserPrefs.toDisplay(suggLb, _unit);
      _weightCtl[ex.id] ??= TextEditingController(
        text: defaultDisplay == defaultDisplay.truncateToDouble()
            ? defaultDisplay.toInt().toString()
            : defaultDisplay.toStringAsFixed(1),
      );
    }

    await _syncWeeklyChart();
  }

  Future<void> _syncWeeklyChart() async {
    if (_day == null) return;
    await RepLogger().setRepsForDate(date: _today, reps: _day!.totalReps);
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restRemaining <= 1) {
        t.cancel();
        setState(() => _restRemaining = 0);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rest done — next set ready!')),
        );
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _add30s() => setState(() => _restRemaining += 30);

  Future<void> _addExercise({String? presetName}) async {
    String name = presetName ?? _newExerciseCtl.text.trim();
    if (name.isEmpty) {
      final picked = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ExerciseLibraryPage()),
      );
      if (picked == null) return;
      name = picked;
    }
    final d = await WorkoutStore().addExercise(_today, name);
    if (!mounted) return;
    setState(() {
      _day = d;
      final ex = d.exercises.last;
      _repsCtl[ex.id] = TextEditingController(text: '10');
      final suggLb = _suggestedLb[name];
      final display = suggLb == null
          ? (_unit == WeightUnit.lb ? 135.0 : 60.0)
          : UserPrefs.toDisplay(suggLb, _unit);
      _weightCtl[ex.id] = TextEditingController(
        text: display == display.truncateToDouble()
            ? display.toInt().toString()
            : display.toStringAsFixed(1),
      );
      _newExerciseCtl.clear();
    });

    final best = await WorkoutStats.bestOneRm(name);
    if (!mounted) return;
    _prByName[name] = best;

    await _syncWeeklyChart();
  }

  Future<void> _renameExercise(ExerciseEntry ex) async {
    final controller = TextEditingController(text: ex.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename exercise'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final d = await WorkoutStore().renameExercise(_today, ex.id, newName);
    if (!mounted) return;
    setState(() => _day = d);

    final best = await WorkoutStats.bestOneRm(newName);
    if (!mounted) return;
    _prByName
      ..remove(ex.name)
      ..[newName] = best;
  }

  Future<void> _deleteExercise(ExerciseEntry ex) async {
    final d = await WorkoutStore().deleteExercise(_today, ex.id);
    if (!mounted) return;
    setState(() {
      _day = d;
      _repsCtl.remove(ex.id)?.dispose();
      _weightCtl.remove(ex.id)?.dispose();
      _prByName.remove(ex.name);
    });
    await _syncWeeklyChart();
  }

  Future<void> _addSet(ExerciseEntry ex) async {
    final reps = int.tryParse(
        (_repsCtl[ex.id] ?? TextEditingController(text: '10')).text.trim());
    final display = double.tryParse(
        (_weightCtl[ex.id] ?? TextEditingController(text: '0')).text.trim());
    if (reps == null || reps <= 0 || display == null || display < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter valid reps/weight.')));
      return;
    }
    final weightLb = UserPrefs.fromDisplay(display, _unit);

    final prevBest = _prByName[ex.name] ?? await WorkoutStats.bestOneRm(ex.name);
    final newEst = WorkoutStats.epley1RM(reps, weightLb);

    final d = await WorkoutStore().addSet(_today, ex.id, reps, weightLb);
    if (!mounted) return;
    setState(() => _day = d);
    await _syncWeeklyChart();
    _startRestTimer(_restDefault);

    if (newEst > (prevBest + 0.0001)) {
      _prByName[ex.name] = newEst;
      if (!mounted) return;
      final pretty = newEst.round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 New PR for ${ex.name}: ~$pretty lb (est. 1RM)')),
      );
    }
  }

  Future<void> _duplicateLastSet(ExerciseEntry ex) async {
    if (ex.sets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No previous set.')));
      return;
    }
    final last = ex.sets.last;
    final d = await WorkoutStore().addSet(_today, ex.id, last.reps, last.weight);
    if (!mounted) return;
    setState(() => _day = d);
    await _syncWeeklyChart();
    _startRestTimer(_restDefault);
  }

  Future<void> _editSet(ExerciseEntry ex, SetEntry s) async {
    final repsCtl = TextEditingController(text: s.reps.toString());
    final disp = UserPrefs.toDisplay(s.weight, _unit);
    final weightCtl = TextEditingController(
      text: disp == disp.truncateToDouble()
          ? disp.toInt().toString()
          : disp.toStringAsFixed(1),
    );

    final result = await showDialog<Map<String, num>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (${_unit == WeightUnit.lb ? 'lb' : 'kg'})',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final r = int.tryParse(repsCtl.text.trim());
              final w = double.tryParse(weightCtl.text.trim());
              if (r == null || r <= 0 || w == null || w < 0) {
                Navigator.pop(ctx, null);
              } else {
                Navigator.pop(ctx, {'reps': r, 'disp': w});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;

    final newLb = UserPrefs.fromDisplay(result['disp']!.toDouble(), _unit);
    final d = await WorkoutStore()
        .updateSet(_today, ex.id, s.id, reps: result['reps']!.toInt(), weight: newLb);
    if (!mounted) return;
    setState(() => _day = d);
    await _syncWeeklyChart();

    final best = await WorkoutStats.bestOneRm(ex.name);
    if (!mounted) return;
    _prByName[ex.name] = best;
  }

  Future<void> _deleteSet(ExerciseEntry ex, SetEntry s) async {
    final d = await WorkoutStore().deleteSet(_today, ex.id, s.id);
    if (!mounted) return;
    setState(() => _day = d);
    await _syncWeeklyChart();

    final best = await WorkoutStats.bestOneRm(ex.name);
    if (!mounted) return;
    _prByName[ex.name] = best;
  }

  Future<void> _clearDay() async {
    await WorkoutStore().clearDay(_today);
    if (!mounted) return;
    setState(() {
      _day = DailyWorkout.empty(_today);
      for (final c in _repsCtl.values) {
        c.dispose();
      }
      for (final c in _weightCtl.values) {
        c.dispose();
      }
      _repsCtl.clear();
      _weightCtl.clear();
      _prByName.clear();
      _cancelRestTimer();
    });
    await _syncWeeklyChart();
  }

  Future<void> _showPlatesFor(ExerciseEntry ex) async {
    final wc = _weightCtl[ex.id] ??
        TextEditingController(text: _unit == WeightUnit.lb ? '135' : '60');
    final display = double.tryParse(wc.text.trim());
    if (display == null || display <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a target weight first.')));
      return;
    }
    final bar = await UserPrefs.barWeight(_unit);
    final b = await PlateMath.compute(
      targetDisplay: display,
      unit: _unit,
      barDisplay: bar,
    );

    String sideText() {
      if (!b.possible && b.target < b.bar) return 'Target is below the bar.';
      if (b.perSide.isEmpty && b.remainder == 0) return 'No plates needed — just the bar.';
      final sizes = b.perSide.keys.toList()..sort((a, c) => c.compareTo(a));
      final parts =
          sizes.map((s) => '${s == s.truncateToDouble() ? s.toInt() : s} × ${b.perSide[s]}').toList();
      var txt = parts.join('  •  ');
      if (b.remainder != 0) {
        txt +=
            '  (leftover ${b.remainder.toStringAsFixed(2)} ${_unit == WeightUnit.lb ? 'lb' : 'kg'} per side)';
      }
      return txt;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plates per side'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${_fmtWeight(display)}   •   Bar: ${_fmtWeight(bar)}'),
            const SizedBox(height: 8),
            Text(sideText()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final numFmt = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProgramTemplatesPage())),
          ),
          IconButton(
            tooltip: 'Library',
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () async {
              final picked = await Navigator.of(context)
                  .push<String>(MaterialPageRoute(builder: (_) => const ExerciseLibraryPage()));
              if (picked != null) _addExercise(presetName: picked);
            },
          ),
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseInsightsPage(
                  initialExercise:
                      _day?.exercises.isNotEmpty == true ? _day!.exercises.first.name : null,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WorkoutHistoryPage())),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsPage()))
                .then((_) => _load()),
          ),
          if (day != null && day.exercises.isNotEmpty)
            IconButton(
              tooltip: 'Clear today',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearDay,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading || day == null)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(day, numFmt),
                const SizedBox(height: 8),
                const StreakGoalHeader(),
                const SizedBox(height: 12),
                _addExerciseRow(),
                const SizedBox(height: 12),
                ...day.exercises.map((ex) => _exerciseCard(ex, numFmt)),
                if (day.exercises.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No exercises yet today. Add your first one!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          if (_restRemaining > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 8),
                        Text(
                          'Rest: ${_restRemaining ~/ 60}:${(_restRemaining % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ]),
                      Row(children: [
                        TextButton(onPressed: _add30s, child: const Text('+30s')),
                        const SizedBox(width: 8),
                        TextButton(
                            onPressed: _cancelRestTimer, child: const Text('Cancel')),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(DailyWorkout day, NumberFormat fmt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.summarize),
          const SizedBox(width: 10),
          Text(
            'Total load today: ${day.totalReps} reps • ${_fmtLoad(day.totalVolume, fmt)} • ${day.exercises.length} exercises',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  Widget _addExerciseRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _newExerciseCtl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Add exercise (e.g., Bench Press)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addExercise(),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ExerciseLibraryPage()))
                .then((v) => v != null ? _addExercise(presetName: v as String) : null),
            icon: const Icon(Icons.library_add),
            label: const Text('Library'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ]),
      ),
    );
  }

  Widget _exerciseCard(ExerciseEntry ex, NumberFormat fmt) {
    final repsCtl =
        _repsCtl[ex.id] ??= TextEditingController(text: '10');
    final weightCtl =
        _weightCtl[ex.id] ??= TextEditingController(text: _unit == WeightUnit.lb ? '135' : '60');
    final timeFmt = DateFormat('h:mm a');

    final maxWlb =
        ex.sets.fold<double>(0, (m, s) => s.weight > m ? s.weight : m);
    final maxWdisp = UserPrefs.toDisplay(maxWlb, _unit);
    final pr = _prByName[ex.name];
    final prText =
        (pr != null && pr > 0) ? ' • PR ${fmt.format(pr.round())} lb' : '';
    final topSetText =
        maxWlb > 0 ? ' • top set ${_fmtWeight(maxWdisp)}' : '';

    final weightChips = UserPrefs.weightChips(_unit);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(ex.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${ex.totalReps} reps • ${_fmtLoad(ex.totalVolume, fmt)}$topSetText$prText'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      tooltip: 'Rename',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _renameExercise(ex)),
                  IconButton(
                      tooltip: 'Delete exercise',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteExercise(ex)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: repsCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: weightCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight (${_unit == WeightUnit.lb ? 'lb' : 'kg'})',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _addSet(ex),
                icon: const Icon(Icons.add_task),
                label: const Text('Add set'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _duplicateLastSet(ex),
                icon: const Icon(Icons.copy),
                label: const Text('Duplicate'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Plate breakdown',
                icon: const Icon(Icons.fitness_center),
                onPressed: () => _showPlatesFor(ex),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [5, 8, 10, 12, 15]
                  .map((v) => ActionChip(
                        label: Text('$v'),
                        onPressed: () => setState(() => repsCtl.text = '$v'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: weightChips
                  .map((w) => ActionChip(
                        label: Text(_fmtWeight(w)),
                        onPressed: () => setState(() => weightCtl.text = w.toString()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            if (ex.sets.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ex.sets.map((s) {
                  final timeLabel = timeFmt.format(s.time);
                  final disp = UserPrefs.toDisplay(s.weight, _unit);
                  return InputChip(
                    label: Text('${s.reps}×${_fmtWeight(disp)} • $timeLabel'),
                    onPressed: () => _editSet(ex, s),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => _deleteSet(ex, s),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
