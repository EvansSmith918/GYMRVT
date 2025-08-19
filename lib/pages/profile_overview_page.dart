import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymrvt/main.dart';
import 'package:gymrvt/services/weight_history.dart';
import 'package:gymrvt/widgets/app_background.dart';
import 'package:gymrvt/pages/profile_page.dart';

class ProfileOverviewPage extends StatefulWidget {
  const ProfileOverviewPage({super.key});

  @override
  State<ProfileOverviewPage> createState() => _ProfileOverviewPageState();
}

class _ProfileOverviewPageState extends State<ProfileOverviewPage> {
  String _name = '';
  String _gender = 'Male';
  int _age = 0;
  int _heightFt = 0;
  int _heightIn = 0;
  double _weightLb = 0;
  File? _avatar;

  List<WeightEntry> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    final gender = prefs.getString('gender') ?? 'Male';
    final ageStr = prefs.getString('age') ?? '';
    final weightStr = prefs.getString('weight') ?? '';
    final ftStr = prefs.getString('height_feet') ?? '';
    final inStr = prefs.getString('height_inches') ?? '';
    final img = prefs.getString('profileImage');

    final hist = await WeightHistory().all();

    if (!mounted) return;
    setState(() {
      _name = name;
      _gender = gender;
      _age = int.tryParse(ageStr) ?? 0;
      _weightLb = double.tryParse(weightStr) ?? 0;
      _heightFt = int.tryParse(ftStr) ?? 0;
      _heightIn = int.tryParse(inStr) ?? 0;
      _avatar = (img != null && File(img).existsSync()) ? File(img) : null;
      _history = hist;
      _loading = false;
    });
  }

  double _bmi() {
    final totalIn = (_heightFt * 12) + _heightIn;
    if (totalIn <= 0) return 0;
    return (_weightLb / (totalIn * totalIn)) * 703.0;
  }

  String _deltaSinceLast() {
    if (_history.length < 2) return '–';
    final latest = _history.last.weightLb;
    final prev = _history[_history.length - 2].weightLb;
    final d = latest - prev;
    if (d == 0) return '0 lb';
    final sign = d > 0 ? '+' : '–';
    return '$sign${d.abs().toStringAsFixed(1)} lb';
  }

  Future<void> _addWeighIn() async {
    final controller = TextEditingController(
      text: _weightLb > 0 ? _weightLb.toStringAsFixed(1) : '',
    );
    final val = await showDialog<double?>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Add weigh-in (lb)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 175.0'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (val == null) return;
    await WeightHistory().upsertToday(val);
    if (!mounted) return;
    setState(() {
      _weightLb = val;
      _loading = true;
    });
    await _load();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile overview'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home),
              onPressed: _goHome,
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                        child: _avatar == null ? const Icon(Icons.person, size: 28) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _name.isEmpty ? 'Your profile' : _name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: _stat('Age', _age > 0 ? '$_age' : '–')),
                          Expanded(child: _stat('Gender', _gender)),
                          Expanded(child: _stat('Height', _heightLabel())),
                          Expanded(child: _stat(
                              'Weight', _weightLb > 0 ? '${_weightLb.toStringAsFixed(1)} lb' : '–')),
                          Expanded(child: _stat('BMI', _bmi() > 0 ? _bmi().toStringAsFixed(1) : '–')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Weight trend (last 14 entries)',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _addWeighIn,
                                icon: const Icon(Icons.monitor_weight),
                                label: const Text('Add weigh-in'),
                              ),
                            ],
                          ),
                          if (_history.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No entries yet — add your first weigh-in.'),
                            )
                          else
                            SizedBox(
                              height: 180,
                              child: _WeightLineChart(entries: _history.takeLast(14).toList()),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.trending_up, size: 18),
                              const SizedBox(width: 6),
                              const Text('Change since last entry:'),
                              const SizedBox(width: 6),
                              Text(_deltaSinceLast(),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _goHome,
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Home'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _heightLabel() {
    if (_heightFt == 0 && _heightIn == 0) return '–';
    return "$_heightFt' $_heightIn\"";
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compact();
    final points = <FlSpot>[];
    final base = entries.first.date;
    for (final e in entries) {
      final days = e.date.difference(base).inDays.toDouble();
      points.add(FlSpot(days, e.weightLb));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(fmt.format(v), style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final d = base.add(Duration(days: v.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat.Md().format(d),
                      style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            dotData: const FlDotData(show: false),
            barWidth: 3,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
