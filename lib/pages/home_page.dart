// lib/pages/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/goal_service.dart';
import 'package:gymrvt/services/muscle_advisor.dart';

import 'package:gymrvt/widgets/streak_goal_header.dart';
import 'package:gymrvt/widgets/weekly_reps_chart.dart';
import 'package:gymrvt/pages/workout_page.dart';
import 'package:gymrvt/pages/workout_history_page.dart';
import 'package:gymrvt/pages/exercise_library_page.dart';
import 'package:gymrvt/pages/program_templates_page.dart';
import 'package:gymrvt/pages/settings_page.dart';

// NEW: Nutrition card
import 'package:gymrvt/widgets/todays_macros_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  File? _profileImage;

  // Today / Yesterday
  int _todayReps = 0;
  double _todayVolumeLb = 0;
  int _ydayReps = 0;
  double _ydayVolumeLb = 0;

  // Week summary
  int _weekWorkouts = 0;
  int _weekGoal = 3;
  int _weekReps = 0;
  double _weekVolumeLb = 0;

  // Weekly group breakdown (for pie)
  Map<String, double> _weekGroupVolume = const {};

  // AI Insight (history-based)
  String? _insightSummary;
  List<String> _insightFocus = const [];
  List<String> _insightCaution = const [];

  // Recent
  List<DailyWorkout> _recent = const [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');

    // profile image
    File? avatar;
    final imagePath = prefs.getString('profileImage');
    if (imagePath != null && File(imagePath).existsSync()) {
      avatar = File(imagePath);
    }

    // today summary
    final today = DateTime.now();
    final todayW = await WorkoutStore().getDay(today);

    // yesterday
    final yday = today.subtract(const Duration(days: 1));
    final ydayW = await WorkoutStore().getDay(yday);

    // weekly progress + goal
    final (done, goal) = await GoalService.weekProgress();

    // compute this week’s totals + muscle group breakdown
    final (weekReps, weekVol) = await _computeThisWeek();
    final groups = await _computeThisWeekGroupBreakdown();

    // Insight (history only – no photo)
    final advice = await MuscleAdvisor.analyze(); // uses your workout history

    // recent 5 logged days
    final recent = await _loadRecent(5);

    if (!mounted) return;
    setState(() {
      _userName = name;
      _profileImage = avatar;

      _todayReps = todayW.totalReps;
      _todayVolumeLb = todayW.totalVolume;
      _ydayReps = ydayW.totalReps;
      _ydayVolumeLb = ydayW.totalVolume;

      _weekWorkouts = done;
      _weekGoal = goal;
      _weekReps = weekReps;
      _weekVolumeLb = weekVol;

      _weekGroupVolume = groups;

      _insightSummary = advice.summary;
      _insightFocus = advice.focus;
      _insightCaution = advice.caution;

      _recent = recent;
      _loading = false;
    });
  }

  /// Returns (reps, volumeLb) for current Monday–Sunday.
  Future<(int, double)> _computeThisWeek() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday + 6) % 7));
    int reps = 0;
    double volume = 0;

    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final w = await WorkoutStore().getDay(d);
      reps += w.totalReps;
      volume += w.totalVolume;
    }
    return (reps, volume);
  }

  /// Crude mapping to bucket an exercise name into muscle groups
  /// (kept local to avoid a hard dependency on private members).
  static final Map<String, List<String>> _nameToGroups = {
    'bench': ['Chest', 'Triceps', 'Front delts'],
    'press': ['Shoulders', 'Triceps'],
    'ohp': ['Shoulders', 'Triceps'],
    'incline': ['Upper chest', 'Front delts'],
    'push-up': ['Chest', 'Triceps'],
    'push up': ['Chest', 'Triceps'],
    'dip': ['Triceps', 'Chest'],
    'curl': ['Biceps'],
    'pull-up': ['Lats', 'Biceps'],
    'pull up': ['Lats', 'Biceps'],
    'row': ['Lats', 'Mid-back', 'Biceps'],
    'face pull': ['Rear delts', 'Upper back'],
    'lateral': ['Side delts'],

    // Lower
    'squat': ['Quads', 'Glutes', 'Core'],
    'deadlift': ['Glutes', 'Hamstrings', 'Lower back'],
    'rdl': ['Hamstrings', 'Glutes'],
    'leg press': ['Quads', 'Glutes'],
    'lunge': ['Quads', 'Glutes'],
    'calf': ['Calves'],

    // Core
    'plank': ['Core'],
    'crunch': ['Abs'],
    'sit-up': ['Abs'],
  };

  List<String> _groupsFor(String name) {
    final n = name.toLowerCase();
    final hits = <String>{};
    for (final k in _nameToGroups.keys) {
      if (n.contains(k)) hits.addAll(_nameToGroups[k]!);
    }
    // very light guessing if no match
    if (hits.isEmpty) {
      if (n.contains('press')) hits.addAll(['Shoulders', 'Triceps']);
      if (n.contains('row') || n.contains('pull')) hits.addAll(['Lats', 'Biceps']);
    }
    return hits.toList();
  }

  Future<Map<String, double>> _computeThisWeekGroupBreakdown() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday + 6) % 7));
    final map = <String, double>{};

    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final w = await WorkoutStore().getDay(d);
      for (final ex in w.exercises) {
        final groups = _groupsFor(ex.name);
        if (groups.isEmpty) continue;
        final vol = ex.totalVolume;
        final share = vol / groups.length;
        for (final g in groups) {
          map[g] = (map[g] ?? 0) + share;
        }
      }
    }
    // drop tiny segments
    map.removeWhere((_, v) => v <= 0);
    return map;
  }

  Future<List<DailyWorkout>> _loadRecent(int maxItems) async {
    final all = await WorkoutStore().allDays(newestFirst: true);
    final withSets =
        all.where((d) => d.exercises.any((e) => e.sets.isNotEmpty)).toList();
    return withSets.take(maxItems).toList();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _humanDate(String ymd) {
    final d = DailyWorkout.parseYmd(ymd);
    final today = DateTime.now();
    final just = DateTime(d.year, d.month, d.day);
    final todayJust = DateTime(today.year, today.month, today.day);
    final diff = just.difference(todayJust).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    return DateFormat.MMMd().format(d);
  }

  String _fmtLb(double v) {
    final fmt = NumberFormat.decimalPattern();
    return '${fmt.format(v.round())} lb';
  }

  (String icon, String text, Color color) _trendVsYesterday() {
    // choose volume trend, fallback to reps
    final base = _ydayVolumeLb > 0 ? _ydayVolumeLb : _ydayReps.toDouble();
    final now = _ydayVolumeLb > 0 ? _todayVolumeLb : _todayReps.toDouble();
    if (base <= 0) return ('•', '1st day logged', Colors.white70);
    final pct = ((now - base) / base * 100).clamp(-999, 999);
    if (pct >= 0) {
      return ('▲', '+${pct.toStringAsFixed(0)}% vs yesterday', Colors.white);
    } else {
      return ('▼', '${pct.toStringAsFixed(0)}% vs yesterday', Colors.white70);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final (arrow, trendTxt, trendColor) = _trendVsYesterday();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting + avatar + settings
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_greeting()}${_userName != null && _userName!.trim().isNotEmpty ? ', $_userName' : ''} 👋',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SettingsPage()))
                    .then((_) => _loadAll()),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickAction(
                icon: Icons.fitness_center,
                label: 'Start workout',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutPage()),
                ),
              ),
              _quickAction(
                icon: Icons.history,
                label: 'History',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutHistoryPage()),
                ),
              ),
              _quickAction(
                icon: Icons.library_books,
                label: 'Library',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExerciseLibraryPage()),
                ),
              ),
              _quickAction(
                icon: Icons.assignment,
                label: 'Templates',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgramTemplatesPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Streak + weekly goal
          const StreakGoalHeader(),
          const SizedBox(height: 12),

          // Today card with trend vs yesterday
          _todayCard(trendArrow: arrow, trendText: trendTxt, trendColor: trendColor),

          const SizedBox(height: 12),

          // Nutrition: today's macros + coach line + Log meal / Scan barcode
          const TodaysMacrosCard(),

          const SizedBox(height: 12),

          // AI Insight card (history-based)
          _insightCard(),

          const SizedBox(height: 12),

          // Volume by Muscle Group (this week)
          _volumeByGroupCard(),

          const SizedBox(height: 12),

          // Weekly reps chart + goal block
          const WeeklyRepsChart(),
          const SizedBox(height: 12),
          _thisWeekStats(),

          const SizedBox(height: 16),

          // Recent workouts
          Text('Recent workouts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No logged workouts yet. Start one now!',
                    style: theme.textTheme.bodyMedium),
              ),
            )
          else
            ..._recent.map(_recentTile),
        ],
      ),
    );
  }

  // ---- UI bits ----
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      elevation: 1,
    );
  }

  Widget _todayCard({
    required String trendArrow,
    required String trendText,
    required Color trendColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text('$_todayReps reps • ${_fmtLb(_todayVolumeLb)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(trendArrow, style: TextStyle(color: trendColor)),
                    const SizedBox(width: 6),
                    Text(trendText, style: TextStyle(color: trendColor)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 36),
        ],
      ),
    );
  }

  Widget _insightChip(String label, {Color? color, IconData? icon}) {
    return Chip(
      label: Text(label),
      backgroundColor: color?.withOpacity(0.15),
      avatar: icon != null ? Icon(icon, size: 16, color: color) : null,
      side: BorderSide(color: (color ?? Colors.white24).withOpacity(0.4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _insightCard() {
    final s = _insightSummary ?? 'Analyzing your recent training…';
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, size: 18),
                SizedBox(width: 6),
                Text('This week’s insight', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(s),
            if (_insightFocus.isNotEmpty || _insightCaution.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._insightFocus.map(
                    (g) => _insightChip('Focus: $g', color: Colors.green, icon: Icons.add),
                  ),
                  ..._insightCaution.map(
                    (c) => _insightChip(c, color: Colors.amber, icon: Icons.warning_amber),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _volumeByGroupCard() {
    if (_weekGroupVolume.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: const [
              Icon(Icons.pie_chart_outline),
              SizedBox(width: 8),
              Expanded(child: Text('Log some workouts to see muscle group volume.')),
            ],
          ),
        ),
      );
    }

    // take top 6 groups to keep chart readable
    final entries = _weekGroupVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final total = top.fold<double>(0, (s, e) => s + e.value);

    final sections = <PieChartSectionData>[];
    final colors = <Color>[
      Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink, Colors.green
    ];
    for (int i = 0; i < top.length; i++) {
      final e = top[i];
      final pct = (e.value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: e.value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 46,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          color: colors[i % colors.length],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, size: 18),
                SizedBox(width: 6),
                Text('Volume by muscle group (this week)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                for (int i = 0; i < top.length; i++)
                  _legendDot(
                    color: colors[i % colors.length],
                    label: top[i].key,
                    value: _fmtLb(top[i].value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label — $value', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _thisWeekStats() {
    final pct = _weekGoal == 0 ? 0.0 : (_weekWorkouts / _weekGoal).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('This week', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('$_weekWorkouts/$_weekGoal days'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _statTile('Total reps', '$_weekReps')),
                Expanded(child: _statTile('Volume', _fmtLb(_weekVolumeLb))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _recentTile(DailyWorkout d) {
    final title = _humanDate(d.ymd);
    final reps = d.totalReps;
    final vol = d.totalVolume;
    final exCount = d.exercises.length;

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$exCount exercises • $reps reps • ${_fmtLb(vol)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkoutHistoryPage()),
        ),
      ),
    );
  }
}
