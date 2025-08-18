import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/rep_logger.dart';

class WorkoutDayViewPage extends StatefulWidget {
  final String ymd;
  const WorkoutDayViewPage({super.key, required this.ymd});

  @override
  State<WorkoutDayViewPage> createState() => _WorkoutDayViewPageState();
}

class _WorkoutDayViewPageState extends State<WorkoutDayViewPage> {
  DailyWorkout? _day;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final date = DailyWorkout.parseYmd(widget.ymd);
    final d = await WorkoutStore().getDay(date);
    if (!mounted) return;
    setState(() {
      _day = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');
    final numFmt = NumberFormat.decimalPattern();

    final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = widget.ymd == todayYmd;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isToday ? 'Today' : dateFmt.format(DailyWorkout.parseYmd(widget.ymd))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isToday && _day != null && _day!.exercises.isNotEmpty)
            TextButton.icon(
              onPressed: _duplicateToToday,
              icon: const Icon(Icons.file_copy_outlined),
              label: const Text('Duplicate to Today'),
            ),
        ],
      ),
      body: _loading || _day == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${_day!.totalReps} reps • ${numFmt.format(_day!.totalVolume.round())} lb • ${_day!.exercises.length} exercises',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._day!.exercises.map((ex) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ex.sets.map((s) {
                                final wl = s.weight == s.weight.truncateToDouble()
                                    ? s.weight.toInt().toString()
                                    : s.weight.toStringAsFixed(1);
                                return Chip(label: Text('${s.reps} × $wl • ${timeFmt.format(s.time)}'));
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  Future<void> _duplicateToToday() async {
    final dest = await WorkoutStore().duplicateDayTo(DailyWorkout.parseYmd(widget.ymd), DateTime.now());
    // keep weekly chart in sync for today
    await RepLogger().setRepsForDate(date: DateTime.now(), reps: dest.totalReps);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to today.')),
    );
  }
}
