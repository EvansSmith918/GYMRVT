import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/pages/workout_day_view_page.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<DailyWorkout> _days = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = await WorkoutStore().allDays();
    if (!mounted) return;
    setState(() {
      _days = days;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final numFmt = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
              ? const Center(child: Text('No history yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final d = _days[i];
                    final date = DailyWorkout.parseYmd(d.ymd);
                    return Card(
                      child: ListTile(
                        title: Text(dateFmt.format(date)),
                        subtitle: Text('${d.totalReps} reps • ${numFmt.format(d.totalVolume.round())} lb • ${d.exercises.length} exercises'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => WorkoutDayViewPage(ymd: d.ymd)));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

