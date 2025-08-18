import 'package:flutter/material.dart';
import 'package:gymrvt/services/user_prefs.dart';
import 'package:gymrvt/services/export_csv.dart';
import 'package:gymrvt/services/goal_service.dart';
import 'package:gymrvt/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  WeightUnit _unit = WeightUnit.lb;
  final _restCtl = TextEditingController(text: '90');
  final _barCtl = TextEditingController(text: '45');

  // goals & reminder
  int _weeklyGoal = 3;
  bool _remOn = false;
  TimeOfDay _remTime = const TimeOfDay(hour: 18, minute: 0);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await UserPrefs.unit();
    final r = await UserPrefs.restSeconds();
    final b = await UserPrefs.barWeight(u);
    final wg = await GoalService.weeklyGoal();
    final (on, h, m) = await GoalService.reminder();

    if (!mounted) return;
    setState(() {
      _unit = u;
      _restCtl.text = r.toString();
      _barCtl.text = b.toStringAsFixed(b == b.truncateToDouble() ? 0 : 1);
      _weeklyGoal = wg;
      _remOn = on;
      _remTime = TimeOfDay(hour: h, minute: m);
      _loading = false;
    });
  }

  Future<void> _saveBase() async {
    final r = int.tryParse(_restCtl.text.trim()) ?? 90;
    final b = double.tryParse(_barCtl.text.trim()) ?? (_unit == WeightUnit.lb ? 45.0 : 20.0);
    await UserPrefs.setUnit(_unit);
    await UserPrefs.setRestSeconds(r);
    await UserPrefs.setBarWeight(_unit, b);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved settings.')));
  }

  Future<void> _saveGoals() async {
    await GoalService.setWeeklyGoal(_weeklyGoal);
    await NotificationService().init();
    await GoalService.setReminder(
      on: _remOn, hour: _remTime.hour, minute: _remTime.minute,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved goals & reminder.')));
  }

  Future<void> _export() async {
    final path = await ExportCsv.exportAndShare();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.transparent, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Units
                Card(
                  child: ListTile(
                    title: const Text('Units'),
                    subtitle: Text(_unit == WeightUnit.lb ? 'Pounds (lb)' : 'Kilograms (kg)'),
                    trailing: DropdownButton<WeightUnit>(
                      value: _unit,
                      onChanged: (v) async {
                        if (v == null) return;
                        final currentBar = await UserPrefs.barWeight(v);
                        setState(() {
                          _unit = v;
                          _barCtl.text = currentBar.toStringAsFixed(
                              currentBar == currentBar.truncateToDouble() ? 0 : 1);
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: WeightUnit.lb, child: Text('lb')),
                        DropdownMenuItem(value: WeightUnit.kg, child: Text('kg')),
                      ],
                    ),
                  ),
                ),
                // Bar
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: Text('Bar weight (${_unit == WeightUnit.lb ? 'lb' : 'kg'})'),
                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _barCtl,
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                ),
                // Rest
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Default rest timer (seconds)'),
                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _restCtl,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveBase,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),

                // Goals
                const SizedBox(height: 24),
                Text('Goals & Reminders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Weekly goal (workouts)'),
                    subtitle: Text('How many days you aim to train this week'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => setState(() => _weeklyGoal = (_weeklyGoal - 1).clamp(1, 14)),
                        ),
                        Text('$_weeklyGoal'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _weeklyGoal = (_weeklyGoal + 1).clamp(1, 14)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Daily reminder'),
                    subtitle: Text('At ${_remTime.format(context)}'),
                    trailing: Switch(
                      value: _remOn,
                      onChanged: (v) => setState(() => _remOn = v),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _remTime);
                      if (picked != null) setState(() => _remTime = picked);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveGoals,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Save goals & reminder'),
                ),

                // Export
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
    );
  }
}
