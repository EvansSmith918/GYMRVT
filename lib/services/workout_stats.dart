import 'dart:math';
import 'package:gymrvt/services/workout_store.dart';

class ExercisePoint {
  final DateTime date;
  final double value;
  ExercisePoint(this.date, this.value);
}

class WorkoutStats {
  /// Epley 1RM estimate: w * (1 + r/30)
  static double epley1RM(int reps, double weight) {
    if (reps <= 0 || weight <= 0) return 0;
    return weight * (1 + reps / 30.0);
  }

  static String _norm(String name) => name.trim().toLowerCase();

  /// Unique exercise names (case-insensitive), preserving first-seen casing.
  static Future<List<String>> allExerciseNames() async {
    final days = await WorkoutStore().allDays();
    final seen = <String, String>{};
    for (final d in days) {
      for (final ex in d.exercises) {
        final k = _norm(ex.name);
        seen.putIfAbsent(k, () => ex.name);
      }
    }
    final out = seen.values.toList();
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// Best (max) estimated 1RM for an exercise across all time.
  static Future<double> bestOneRm(String exerciseName) async {
    final days = await WorkoutStore().allDays();
    final key = _norm(exerciseName);
    double best = 0;
    for (final d in days) {
      for (final ex in d.exercises) {
        if (_norm(ex.name) != key) continue;
        for (final s in ex.sets) {
          best = max(best, epley1RM(s.reps, s.weight));
        }
      }
    }
    return best;
  }

  /// Daily max 1RM timeline for one exercise.
  static Future<List<ExercisePoint>> oneRmTimeline(String exerciseName) async {
    final days = await WorkoutStore().allDays(newestFirst: false);
    final key = _norm(exerciseName);
    final pts = <ExercisePoint>[];
    for (final d in days) {
      double dayMax = 0;
      for (final ex in d.exercises) {
        if (_norm(ex.name) != key) continue;
        for (final s in ex.sets) {
          dayMax = max(dayMax, epley1RM(s.reps, s.weight));
        }
      }
      if (dayMax > 0) {
        pts.add(ExercisePoint(DailyWorkout.parseYmd(d.ymd), dayMax));
      }
    }
    return pts;
  }

  /// Daily volume (sum reps*weight) timeline for one exercise.
  static Future<List<ExercisePoint>> volumeTimeline(String exerciseName) async {
    final days = await WorkoutStore().allDays(newestFirst: false);
    final key = _norm(exerciseName);
    final pts = <ExercisePoint>[];
    for (final d in days) {
      double vol = 0;
      for (final ex in d.exercises) {
        if (_norm(ex.name) != key) continue;
        vol += ex.totalVolume;
      }
      if (vol > 0) {
        pts.add(ExercisePoint(DailyWorkout.parseYmd(d.ymd), vol));
      }
    }
    return pts;
  }
}
