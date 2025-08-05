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
  Map<String, int> _weeklyReps = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final reps = await RepLogger().getRepsLast7Days();
    setState(() {
      _weeklyReps = reps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _weeklyReps.keys.toList().reversed.toList(); // Oldest to newest
    final values = days.map((d) => _weeklyReps[d]!.toDouble()).toList();

    return Card(
      color: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reps (Last 7 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) return const SizedBox.shrink();
                          final date = DateTime.parse(days[index]);
                          return Text(
                            DateFormat.E().format(date),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: List.generate(days.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.orangeAccent,
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
