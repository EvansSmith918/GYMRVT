import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gymrvt/services/rep_logger.dart';
import 'package:intl/intl.dart';

class WeeklyRepsChart extends StatefulWidget {
  const WeeklyRepsChart({super.key});

  @override
  State<WeeklyRepsChart> createState() => _WeeklyRepsChartState();
}

class _WeeklyRepsChartState extends State<WeeklyRepsChart> {
  List<DailyReps> _weeklyReps = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final reps = await RepLogger().getRepsLast7Days();
    if (!mounted) return; // fixes "use_build_context_synchronously" lint
    setState(() {
      _weeklyReps = reps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyReps.isEmpty) {
      return const Text('No reps logged this week yet.');
    }

    final spots = <BarChartGroupData>[];
    final df = DateFormat('E'); // Mon, Tue, ...

    for (int i = 0; i < _weeklyReps.length; i++) {
      final day = _weeklyReps[i];
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: day.reps.toDouble())],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Reps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: spots,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _weeklyReps.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(df.format(_weeklyReps[idx].date), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = _weeklyReps[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('EEE, MMM d').format(d.date)}\n${d.reps} reps',
                          const TextStyle(fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

