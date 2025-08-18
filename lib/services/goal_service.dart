import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymrvt/services/workout_store.dart';
import 'package:gymrvt/services/notification_service.dart';

class GoalService {
  static const _goalKey = 'weekly_goal_workouts';
  static const _remOnKey = 'rem_on';
  static const _remHourKey = 'rem_hour';
  static const _remMinKey = 'rem_min';
  static const _notifId = 101;

  /// ---- Settings ----
  static Future<int> weeklyGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_goalKey) ?? 3; // default: 3 workouts/week
  }

  static Future<void> setWeeklyGoal(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_goalKey, v.clamp(1, 14));
  }

  static Future<(bool on, int hour, int minute)> reminder() async {
    final p = await SharedPreferences.getInstance();
    return (p.getBool(_remOnKey) ?? false, p.getInt(_remHourKey) ?? 18, p.getInt(_remMinKey) ?? 0);
  }

  static Future<void> setReminder({required bool on, required int hour, required int minute}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_remOnKey, on);
    await p.setInt(_remHourKey, hour);
    await p.setInt(_remMinKey, minute);
    if (on) {
      await NotificationService().scheduleDaily(id: _notifId, hour: hour, minute: minute);
    } else {
      await NotificationService().cancel(_notifId);
    }
  }

  /// Call on app start so reminders are live even after reboot.
  static Future<void> ensureScheduledReminderAtLaunch() async {
    final (on, h, m) = await reminder();
    if (on) await NotificationService().scheduleDaily(id: _notifId, hour: h, minute: m);
  }

  /// ---- Progress & Streaks ----
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Set<String>> _workoutDaysHasSets() async {
    final days = await WorkoutStore().allDays();
    final out = <String>{};
    for (final d in days) {
      final hasSets = d.exercises.any((e) => e.sets.isNotEmpty);
      if (hasSets) out.add(d.ymd);
    }
    return out;
  }

  /// Consecutive days up to today with any sets.
  static Future<int> dailyStreak() async {
    final done = await _workoutDaysHasSets();
    int streak = 0;
    var cur = DateTime.now();
    while (done.contains(_ymd(DateTime(cur.year, cur.month, cur.day)))) {
      streak++;
      cur = cur.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Workouts done in the current week (Mon–Sun) + goal.
  static Future<(int done, int goal)> weekProgress() async {
    final done = await _workoutDaysHasSets();
    final goal = await weeklyGoal();

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday + 6) % 7)); // Monday
    final sunday = monday.add(const Duration(days: 6));

    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      if (done.contains(_ymd(d))) count++;
    }
    return (count, goal);
  }
}
