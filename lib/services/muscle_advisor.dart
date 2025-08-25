// lib/services/muscle_advisor.dart
import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:gymrvt/services/workout_store.dart';

class MuscleAdvice {
  final String summary;
  final List<String> focus;   // needs more work
  final List<String> caution; // possibly fatigued / overused
  MuscleAdvice({required this.summary, required this.focus, required this.caution});
}

class MuscleAdvisor {
  /// Keywords => muscle groups (very simple heuristic).
  /// You can expand these lists anytime.
  static final Map<String, List<String>> _map = {
    // Upper
    'bench': ['chest', 'triceps', 'front delts'],
    'press': ['shoulders', 'triceps'],
    'overhead': ['shoulders', 'triceps'],
    'ohp': ['shoulders', 'triceps'],
    'incline': ['upper chest', 'front delts'],
    'push-up': ['chest', 'triceps'],
    'push up': ['chest', 'triceps'],
    'dip': ['triceps', 'chest'],
    'curl': ['biceps'],
    'pull-up': ['lats', 'biceps'],
    'pull up': ['lats', 'biceps'],
    'row': ['lats', 'mid-back', 'biceps'],
    'face pull': ['rear delts', 'upper back'],
    'lateral': ['side delts'],

    // Lower
    'squat': ['quads', 'glutes', 'core'],
    'deadlift': ['glutes', 'hamstrings', 'lower back'],
    'rdl': ['hamstrings', 'glutes'],
    'leg press': ['quads', 'glutes'],
    'lunge': ['quads', 'glutes'],
    'calf': ['calves'],

    // Core
    'plank': ['core'],
    'crunch': ['abs'],
    'sit-up': ['abs'],
  };

  static List<String> _groupsForExercise(String name) {
    final n = name.toLowerCase();
    final hits = <String>{};
    for (final k in _map.keys) {
      if (n.contains(k)) {
        hits.addAll(_map[k]!);
      }
    }
    // if nothing matched, take a guess based on common words
    if (hits.isEmpty) {
      if (n.contains('bench')) hits.addAll(['chest','triceps']);
      if (n.contains('press')) hits.addAll(['shoulders','triceps']);
      if (n.contains('row') || n.contains('pull')) hits.addAll(['lats','biceps']);
    }
    return hits.toList();
  }

  /// Compute recent volume (last 7d vs previous 21d) per muscle group.
  static Future<(Map<String,double> last7, Map<String,double> prev21)> _volumeWindows() async {
    final all = await WorkoutStore().allDays(newestFirst: true);
    final now = DateTime.now();
    final start7  = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final start28 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 27));

    final last7  = <String,double>{};
    final prev21 = <String,double>{};

    for (final d in all) {
      final dt = DailyWorkout.parseYmd(d.ymd);
      if (dt.isBefore(start28)) break;

      for (final ex in d.exercises) {
        final groups = _groupsForExercise(ex.name);
        if (groups.isEmpty) continue;
        final vol = ex.totalVolume;
        final target = dt.isBefore(start7) ? prev21 : last7;
        for (final g in groups) {
          target[g] = (target[g] ?? 0) + vol / groups.length; // split volume
        }
      }
    }
    return (last7, prev21);
  }

  /// Optional: add tiny posture hints when a pose is available.
  static List<String> _postureNotes(Pose? pose) {
    if (pose == null) return const [];
    final lm = pose.landmarks;
    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final lHip = lm[PoseLandmarkType.leftHip];
    final rHip = lm[PoseLandmarkType.rightHip];

    final notes = <String>[];

    if (lShoulder != null && rShoulder != null) {
      final dy = (lShoulder.y - rShoulder.y).abs();
      if (dy > 20) notes.add('Shoulder height looks uneven; add mobility/scap work.');
    }
    if (lHip != null && rHip != null) {
      final dy = (lHip.y - rHip.y).abs();
      if (dy > 20) notes.add('Hip height looks uneven; address glute/hip stability.');
    }
    return notes;
  }

  /// Main entry: combine (optional) pose + your recent training to produce advice.
  static Future<MuscleAdvice> analyze({Pose? pose}) async {
    final (last7, prev21) = await _volumeWindows();

    // Find groups with unusually HIGH recent volume (fatigue) and LOW volume (needs work).
    final focus = <String>[];
    final caution = <String>[];

    // Normalize by prior average to be device/weight agnostic
    for (final g in {...last7.keys, ...prev21.keys}) {
      final recent = last7[g] ?? 0;
      final base = max(prev21[g] ?? 0, 1.0); // avoid /0
      final ratio = recent / (base / 3.0); // prev21 is 3× the days of last7

      // Heuristics:
      if (recent < 200 && ratio < 0.6) {
        focus.add(g); // underworked
      } else if (recent > 800 && ratio > 1.3) {
        caution.add('Possible fatigue in $g — dial back volume or intensity if sore.');
      }
    }

    // Posture notes (optional)
    final notes = _postureNotes(pose);
    caution.addAll(notes);

    String summary;
    if (focus.isEmpty && caution.isEmpty) {
      summary = 'Training looks balanced this week. Keep it up!';
    } else if (focus.isNotEmpty && caution.isNotEmpty) {
      summary = 'Mix of underworked and possibly overworked areas this week.';
    } else if (focus.isNotEmpty) {
      summary = 'Some areas appear underworked this week.';
    } else {
      summary = 'Some areas may be fatigued this week.';
    }

    return MuscleAdvice(summary: summary, focus: focus..sort(), caution: caution);
  }
}


