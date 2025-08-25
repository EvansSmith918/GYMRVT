import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymrvt/services/workout_stats.dart';

class ExerciseInsightsPage extends StatefulWidget {
  final String? initialExercise;
  const ExerciseInsightsPage({super.key, this.initialExercise});

  @override
  State<ExerciseInsightsPage> createState() => _ExerciseInsightsPageState();
}

class _ExerciseInsightsPageState extends State<ExerciseInsightsPage> {
  List<String> _exNames = [];
  String? _selected;
  double _best1rm = 0;
  List<ExercisePoint> _oneRmPts = [];
  List<ExercisePoint> _volPts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final names = await WorkoutStats.allExerciseNames();
    String? start = widget.initialExercise;
    if (start != null && !names.map((e) => e.toLowerCase()).contains(start.toLowerCase())) {
      start = null;
    }
    start ??= names.isNotEmpty ? names.first : null;

    setState(() {
      _exNames = names;
      _selected = start;
    });

    if (start != null) {
      await _loadFor(start);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFor(String name) async {
    setState(() => _loading = true);
    final best = await WorkoutStats.bestOneRm(name);
    final oneRm = await WorkoutStats.oneRmTimeline(name);
    final vol = await WorkoutStats.volumeTimeline(name);
    if (!mounted) return;
    setState(() {
      _best1rm = best;
      _oneRmPts = oneRm;
      _volPts = vol;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Insights';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_exNames.isEmpty)
            const Center(child: Text('Log some workouts to see insights.'))
          else ...[
            _exercisePicker(),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading) ...[
              _prCard(),
              const SizedBox(height: 12),
              _chartCard(
                title: 'Estimated 1RM',
                height: 220,
                child: _oneRmPts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No data yet for this exercise.'),
                        ),
                      )
                    : _lineChart(_oneRmPts),
              ),
              const SizedBox(height: 12),
              _chartCard(
                title: 'Daily Volume (lb)',
                height: 220,
                child: _volPts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No volume logged yet.'),
                        ),
                      )
                    : _barChart(_volPts),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _exercisePicker() {
    return Row(
      children: [
        const Text('Exercise:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selected,
            items: _exNames
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selected = v);
              _loadFor(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _prCard() {
    final numFmt = NumberFormat.decimalPattern();
    final best = _best1rm == _best1rm.truncateToDouble()
        ? _best1rm.toInt().toString()
        : numFmt.format(_best1rm.round());
    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text('All-time PR (est. 1RM): $best lb'),
        subtitle: const Text('Epley formula: w × (1 + r/30)'),
      ),
    );
  }

  Widget _chartCard({required String title, required double height, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(
              height: height,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 16), // space for x-axis labels
                child: SizedBox.expand(), // placeholder; real child added below
              ),
            ),
            // Insert the actual chart below so padding doesn't wrap the title
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------- Charts (fl_chart) -------

  Widget _lineChart(List<ExercisePoint> pts) {
    final xLabels = _buildLabels(pts);
    final spots = List.generate(
      pts.length,
      (i) => FlSpot(i.toDouble(), pts[i].value),
    );
    final minVal = pts.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxVal = pts.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minY = minVal * 0.95;
    final maxY = maxVal * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) <= 1 ? 1.0 : null, // <-- double
              reservedSize: 40.0,                          // <-- double
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(xLabels[i], style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        minX: 0,
        maxX: (pts.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _barChart(List<ExercisePoint> pts) {
    final xLabels = _buildLabels(pts);
    final groups = List.generate(pts.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pts[i].value,
            width: 12.0, // <-- double
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final maxYVal = pts.map((e) => e.value).fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = (maxYVal <= 0 ? 100.0 : maxYVal * 1.1); // <-- doubles

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40.0), // <-- double
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(xLabels[i], style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: groups,
        maxY: maxY,
      ),
    );
  }

  List<String> _buildLabels(List<ExercisePoint> pts) {
    final df = DateFormat('M/d');
    return pts.map((e) => df.format(e.date)).toList();
  }
}
