import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailyReps {
  final DateTime date;
  final int reps;
  const DailyReps(this.date, this.reps);
}

/// Simple local logger that stores a map of "yyyy-MM-dd" -> reps (int)
class RepLogger {
  static const _storeKey = 'rep_log_v1';

  RepLogger._();
  static final RepLogger _singleton = RepLogger._();
  factory RepLogger() => _singleton;

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Add reps to a specific date (accumulates for that day)
  Future<void> logReps({required DateTime date, required int reps}) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storeKey);
    final Map<String, dynamic> data =
        raw == null ? {} : (jsonDecode(raw) as Map<String, dynamic>);

    final key = _ymd(date);
    final current = (data[key] as int?) ?? 0;
    data[key] = current + reps;

    await prefs.setString(_storeKey, jsonEncode(data));
  }

  /// Returns the last 7 days (today inclusive), filling missing days with 0
  Future<List<DailyReps>> getRepsLast7Days() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storeKey);
    final Map<String, dynamic> data =
        raw == null ? {} : (jsonDecode(raw) as Map<String, dynamic>);

    final today = DateTime.now();
    final List<DailyReps> out = [];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final key = _ymd(d);
      final reps = (data[key] as int?) ?? 0;
      out.add(DailyReps(d, reps));
    }
    return out;
  }

  /// Optional helper if you want a fast weekly total
  Future<int> totalThisWeek() async {
    final last7 = await getRepsLast7Days();
    return last7.fold<int>(0, (int sum, DailyReps e) => sum + e.reps);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Clears all logged reps (for testing/reset)
  Future<void> reset() async {
    final prefs = await _prefs;
    await prefs.remove(_storeKey);
  }
}