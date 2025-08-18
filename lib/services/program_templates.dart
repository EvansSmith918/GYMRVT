import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymrvt/services/workout_store.dart';

class TemplateExercise {
  final String name;
  final int targetReps;
  final double startWeightLb;
  final double incrementLb;
  const TemplateExercise(this.name, this.targetReps, this.startWeightLb, this.incrementLb);
}

class TemplateDay {
  final String title;
  final List<TemplateExercise> items;
  const TemplateDay(this.title, this.items);
}

class ProgramTemplate {
  final String id;
  final String name;
  final List<TemplateDay> days;
  const ProgramTemplate(this.id, this.name, this.days);
}

class ProgramTemplates {
  static const _suggestKeyPrefix = 'suggested_weights_';

  static List<ProgramTemplate> all = [
    ProgramTemplate('sl5x5', 'StrongLifts 5×5', [
      TemplateDay('Day A', [
        TemplateExercise('Back Squat', 5, 95, 5),
        TemplateExercise('Bench Press', 5, 65, 5),
        TemplateExercise('Barbell Row', 5, 65, 5),
      ]),
      TemplateDay('Day B', [
        TemplateExercise('Back Squat', 5, 95, 5),
        TemplateExercise('Overhead Press', 5, 45, 5),
        TemplateExercise('Deadlift', 5, 135, 10),
      ]),
    ]),
    ProgramTemplate('ppl', 'Push / Pull / Legs', [
      TemplateDay('Push', [
        TemplateExercise('Bench Press', 8, 95, 5),
        TemplateExercise('Overhead Press', 8, 45, 5),
        TemplateExercise('Dumbbell Curl', 12, 20, 2.5),
      ]),
      TemplateDay('Pull', [
        TemplateExercise('Barbell Row', 10, 65, 5),
        TemplateExercise('Pull-Up', 8, 0, 0),
        TemplateExercise('Lat Pulldown', 12, 70, 5),
      ]),
      TemplateDay('Legs', [
        TemplateExercise('Back Squat', 8, 95, 5),
        TemplateExercise('Romanian Deadlift', 10, 95, 5),
      ]),
    ]),
  ];

  static Future<Map<String, double>> _suggestionsForDay(TemplateDay day) async {
    // Auto-progression: use last performed weight (top set) + increment; else start weight
    final allDays = await WorkoutStore().allDays();
    double lastFor(String name) {
      for (final d in allDays) {
        for (final ex in d.exercises.reversed) {
          if (ex.name.toLowerCase() == name.toLowerCase() && ex.sets.isNotEmpty) {
            return ex.sets.last.weight;
          }
        }
      }
      return double.nan;
    }

    final out = <String, double>{};
    for (final it in day.items) {
      final last = lastFor(it.name);
      out[it.name] = last.isNaN ? it.startWeightLb : (last + it.incrementLb);
    }
    return out;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Save suggested weights (lb) for a date, consumed by WorkoutPage.
  static Future<void> _saveSuggestions(DateTime date, Map<String, double> map) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_suggestKeyPrefix${_ymd(date)}', jsonEncode(map));
  }

  static Future<Map<String, double>> loadSuggestions(DateTime date) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('$_suggestKeyPrefix${_ymd(date)}');
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
  }

  /// Apply a template day: add exercises (no sets), compute and store suggestions.
  static Future<void> applyDayToToday(TemplateDay day) async {
    final store = WorkoutStore();
    final today = DateTime.now();
    final current = await store.getDay(today);

    // Add exercises if missing
    for (final it in day.items) {
      final exists = current.exercises.any((e) => e.name.toLowerCase() == it.name.toLowerCase());
      if (!exists) {
        current.exercises.add(ExerciseEntry.newEmpty(it.name));
      }
    }
    await store.saveDay(current);

    final sugg = await _suggestionsForDay(day);
    await _saveSuggestions(today, sugg);
  }
}
