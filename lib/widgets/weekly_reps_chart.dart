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
  List<DailyReps> _data = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RepLogger().getRepsLast7Days(); // oldest..newest per your service
    if (!mounted) return;
    setState(() {
      _data = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(child: SizedBox(height: 180, child: Center(child: CircularProgressIndicator())));
    }
    if (_data.isEmpty) {
      return const Card(child: SizedBox(height: 120, child: Center(child: Text('No reps logged yet'))));
    }

    // Ensure oldest -> newest
    final items = List<DailyReps>.from(_data);
    items.sort((a, b) => a.date.compareTo(b.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reps (Last 7 days)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, gIndex, rod, rodIndex) {
                        final d = items[group.x.toInt()].date;
                        return BarTooltipItem(
                          '${DateFormat.E().format(d)}\n${rod.toY.toInt()} reps',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= items.length) return const SizedBox.shrink();
                          final d = items[i].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(DateFormat.E().format(d), style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(items.length, (i) {
                    final reps = items[i].reps.toDouble();
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: reps,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFFFFA726), Color(0xFFFF7043)], // orange-ish
                          ),
                        ),
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
