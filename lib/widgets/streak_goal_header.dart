import 'package:flutter/material.dart';
import 'package:gymrvt/services/goal_service.dart';

class StreakGoalHeader extends StatefulWidget {
  const StreakGoalHeader({super.key});

  @override
  State<StreakGoalHeader> createState() => _StreakGoalHeaderState();
}

class _StreakGoalHeaderState extends State<StreakGoalHeader> {
  int _streak = 0;
  int _done = 0;
  int _goal = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GoalService.dailyStreak();
    final (d, g) = await GoalService.weekProgress();
    if (!mounted) return;
    setState(() {
      _streak = s;
      _done = d;
      _goal = g;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(child: SizedBox(height: 64, child: Center(child: CircularProgressIndicator())));
    }
    final pct = (_goal == 0) ? 0.0 : (_done / _goal).clamp(0, 1).toDouble();
    final hit = _done >= _goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(hit ? Icons.emoji_events : Icons.local_fire_department,
                color: hit ? Colors.amber : Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Streak: $_streak day${_streak == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct),
                const SizedBox(height: 4),
                Text('This week: $_done / $_goal workouts'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
