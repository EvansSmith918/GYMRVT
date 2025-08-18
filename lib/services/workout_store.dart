import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SetEntry {
  final String id;
  final int reps;
  final double weight; // lbs
  final DateTime time;

  SetEntry({
    required this.id,
    required this.reps,
    required this.weight,
    required this.time,
  });

  factory SetEntry.newNow({required int reps, required double weight}) =>
      SetEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        reps: reps,
        weight: weight,
        time: DateTime.now(),
      );

  double get volume => reps * weight;

  Map<String, dynamic> toJson() => {
        'id': id,
        'reps': reps,
        'weight': weight,
        'time': time.toIso8601String(),
      };

  factory SetEntry.fromJson(Map<String, dynamic> j) => SetEntry(
        id: (j['id'] as String?) ?? '',
        reps: (j['reps'] as num?)?.toInt() ?? 0,
        weight: (j['weight'] as num?)?.toDouble() ?? 0.0, // default for old data
        time: DateTime.parse(j['time'] as String),
      );
}

class ExerciseEntry {
  final String id;
  final String name;
  final List<SetEntry> sets;

  ExerciseEntry({required this.id, required this.name, required this.sets});

  factory ExerciseEntry.newEmpty(String name) => ExerciseEntry(
        id: 'e_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        sets: [],
      );

  int get totalReps => sets.fold(0, (s, x) => s + x.reps);
  double get totalVolume => sets.fold(0.0, (s, x) => s + x.volume);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets.map((e) => e.toJson()).toList(),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> j) => ExerciseEntry(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        sets: ((j['sets'] as List?) ?? [])
            .map((e) => SetEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class DailyWorkout {
  final String ymd;
  final List<ExerciseEntry> exercises;

  DailyWorkout({required this.ymd, required this.exercises});

  factory DailyWorkout.empty(DateTime d) =>
      DailyWorkout(ymd: _ymd(d), exercises: []);

  int get totalReps => exercises.fold(0, (s, e) => s + e.totalReps);
  double get totalVolume => exercises.fold(0.0, (s, e) => s + e.totalVolume);

  Map<String, dynamic> toJson() => {
        'ymd': ymd,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory DailyWorkout.fromJson(Map<String, dynamic> j) => DailyWorkout(
        ymd: (j['ymd'] as String?) ?? '',
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) => ExerciseEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseYmd(String ymd) {
    final p = ymd.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}

class WorkoutStore {
  static const _key = 'workout_days_v1';

  WorkoutStore._();
  static final WorkoutStore _i = WorkoutStore._();
  factory WorkoutStore() => _i;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<Map<String, DailyWorkout>> _loadAllDays() async {
    final p = await _prefs;
    final raw = p.getString(_key);
    if (raw == null) return {};
    final obj = jsonDecode(raw);
    if (obj is! Map) return {};
    return obj.map<String, DailyWorkout>(
      (k, v) => MapEntry(k as String, DailyWorkout.fromJson((v as Map).cast<String, dynamic>())),
    );
  }

  Future<void> _saveAllDays(Map<String, DailyWorkout> days) async {
    final p = await _prefs;
    await p.setString(_key, jsonEncode(days.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<DailyWorkout> getDay(DateTime date) async {
    final map = await _loadAllDays();
    final key = DailyWorkout._ymd(date);
    return map[key] ?? DailyWorkout.empty(date);
  }

  Future<void> saveDay(DailyWorkout day) async {
    final map = await _loadAllDays();
    map[day.ymd] = day;
    await _saveAllDays(map);
  }

  Future<void> clearDay(DateTime date) async {
    final map = await _loadAllDays();
    map.remove(DailyWorkout._ymd(date));
    await _saveAllDays(map);
  }

  // --------- Mutations ----------
  Future<DailyWorkout> addExercise(DateTime date, String name) async {
    final day = await getDay(date);
    day.exercises.add(ExerciseEntry.newEmpty(name));
    await saveDay(day);
    return day;
  }

  Future<DailyWorkout> renameExercise(DateTime date, String exerciseId, String newName) async {
    final day = await getDay(date);
    final idx = day.exercises.indexWhere((e) => e.id == exerciseId);
    if (idx != -1) {
      day.exercises[idx] = ExerciseEntry(
        id: day.exercises[idx].id,
        name: newName,
        sets: day.exercises[idx].sets,
      );
      await saveDay(day);
    }
    return day;
  }

  Future<DailyWorkout> deleteExercise(DateTime date, String exerciseId) async {
    final day = await getDay(date);
    day.exercises.removeWhere((e) => e.id == exerciseId);
    await saveDay(day);
    return day;
  }

  Future<DailyWorkout> addSet(DateTime date, String exerciseId, int reps, double weight) async {
    final day = await getDay(date);
    final ex = day.exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => ExerciseEntry.newEmpty(''),
    );
    if (ex.id.isEmpty) return day;
    ex.sets.add(SetEntry.newNow(reps: reps, weight: weight));
    await saveDay(day);
    return day;
  }

  Future<DailyWorkout> updateSet(DateTime date, String exerciseId, String setId, {int? reps, double? weight}) async {
    final day = await getDay(date);
    final ex = day.exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => ExerciseEntry.newEmpty(''),
    );
    if (ex.id.isEmpty) return day;
    final idx = ex.sets.indexWhere((s) => s.id == setId);
    if (idx != -1) {
      final old = ex.sets[idx];
      ex.sets[idx] = SetEntry(
        id: old.id,
        reps: reps ?? old.reps,
        weight: weight ?? old.weight,
        time: old.time,
      );
      await saveDay(day);
    }
    return day;
  }

  Future<DailyWorkout> deleteSet(DateTime date, String exerciseId, String setId) async {
    final day = await getDay(date);
    final ex = day.exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => ExerciseEntry.newEmpty(''),
    );
    if (ex.id.isEmpty) return day;
    ex.sets.removeWhere((s) => s.id == setId);
    await saveDay(day);
    return day;
  }

  // --------- History / Utility ----------
  Future<List<DailyWorkout>> allDays({bool newestFirst = true}) async {
    final days = await _loadAllDays();
    final list = days.values.toList();
    list.sort((a, b) => newestFirst ? b.ymd.compareTo(a.ymd) : a.ymd.compareTo(b.ymd));
    return list;
  }

  /// Duplicate all exercises/sets from `from` to `to` (new timestamps).
  Future<DailyWorkout> duplicateDayTo(DateTime from, DateTime to) async {
    final fromDay = await getDay(from);
    final toDay = await getDay(to);
    for (final ex in fromDay.exercises) {
      final copy = ExerciseEntry.newEmpty(ex.name);
      for (final s in ex.sets) {
        copy.sets.add(SetEntry.newNow(reps: s.reps, weight: s.weight));
      }
      toDay.exercises.add(copy);
    }
    await saveDay(toDay);
    return toDay;
  }
}
