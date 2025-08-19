import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/goal_service.dart';

import 'package:gymrvt/widgets/streak_goal_header.dart';
import 'package:gymrvt/widgets/weekly_reps_chart.dart';
import 'package:gymrvt/pages/workout_page.dart';
import 'package:gymrvt/pages/workout_history_page.dart';
import 'package:gymrvt/pages/exercise_library_page.dart';
import 'package:gymrvt/pages/program_templates_page.dart';
import 'package:gymrvt/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  File? _profileImage;

  // Today
  int _todayReps = 0;
  double _todayVolumeLb = 0;

  // Week summary
  int _weekWorkouts = 0;
  int _weekGoal = 3;
  int _weekReps = 0;
  double _weekVolumeLb = 0;

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
    final todayReps = todayW.totalReps;
    final todayVol = todayW.totalVolume;

    // weekly progress + goal
    final (done, goal) = await GoalService.weekProgress();

    // compute this week’s totals
    final (weekReps, weekVol) = await _computeThisWeek();

    // recent 5 logged days
    final recent = await _loadRecent(5);

    if (!mounted) return;
    setState(() {
      _userName = name;
      _profileImage = avatar;
      _todayReps = todayReps;
      _todayVolumeLb = todayVol;
      _weekWorkouts = done;
      _weekGoal = goal;
      _weekReps = weekReps;
      _weekVolumeLb = weekVol;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting + avatar
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_greeting()}${_userName != null && _userName!.trim().isNotEmpty ? ', $_userName' : ''} 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((_) => _loadAll()),
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

          // Reps today card
          _repsTodayCard(),

          const SizedBox(height: 12),
          // Weekly reps chart
          const WeeklyRepsChart(),
          const SizedBox(height: 12),

          // This week stats
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

  Widget _repsTodayCard() {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Texts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Reps logged',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_todayReps reps • ${_fmtLb(_todayVolumeLb)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 36),
        ],
      ),
    );
  }

  Widget _thisWeekStats() {
    final theme = Theme.of(context);
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
                Expanded(
                  child: Text('This week', style: theme.textTheme.titleMedium),
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
    final theme = Theme.of(context);
    final title = _humanDate(d.ymd);
    final reps = d.totalReps;
    final vol = d.totalVolume;
    final exCount = d.exercises.length;

    return Card(
      child: ListTile(
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text('$exCount exercises • $reps reps • ${_fmtLb(vol)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkoutHistoryPage()),
        ),
      ),
    );
  }
}
