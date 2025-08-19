import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeightEntry {
  final DateTime date;
  final double weightLb;

  const WeightEntry(this.date, this.weightLb);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weightLb,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      DateTime.parse(json['date'] as String),
      (json['weight'] as num).toDouble(),
    );
  }
}

class WeightHistory {
  static const _key = 'weight_history_v1';

  WeightHistory._();
  static final WeightHistory _i = WeightHistory._();
  factory WeightHistory() => _i;

  Future<List<WeightEntry>> all() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<WeightEntry> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  /// Insert or replace today's entry.
  Future<void> upsertToday(double weightLb) async {
    final list = await all();
    final today = DateTime.now();
    final ymd = DateTime(today.year, today.month, today.day);

    int idx = list.lastIndexWhere((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d == ymd;
    });

    if (idx >= 0) {
      list[idx] = WeightEntry(today, weightLb);
    } else {
      list.add(WeightEntry(today, weightLb));
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    await _save(list);
  }

  Future<WeightEntry?> latest() async {
    final list = await all();
    if (list.isEmpty) return null;
    return list.last;
  }

  /// Returns the most recent entry that is **before** the given date.
  Future<WeightEntry?> previousBefore(DateTime date) async {
    final list = await all();
    if (list.isEmpty) return null;
    for (int i = list.length - 1; i >= 0; i--) {
      if (list[i].date.isBefore(date)) return list[i];
    }
    return null;
  }
}
