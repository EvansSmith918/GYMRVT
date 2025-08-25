import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Lightweight result object you can display in UI.
class MuscleAdvice {
  final List<String> focus;   // muscles likely working / under load
  final List<String> caution; // potential asymmetry or form issues
  final String summary;

  const MuscleAdvice({
    required this.focus,
    required this.caution,
    required this.summary,
  });
}

class MuscleAdvisor {
  /// Returns the interior angle (in degrees) at landmark B formed by A–B–C.
  static double? _angle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return null;
    final abx = a.x - b.x, aby = a.y - b.y;
    final cbx = c.x - b.x, cby = c.y - b.y;

    final dot = abx * cbx + aby * cby;
    final mag1 = math.sqrt(abx * abx + aby * aby);
    final mag2 = math.sqrt(cbx * cbx + cby * cby);
    if (mag1 == 0 || mag2 == 0) return null;

    final cos = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  /// Very small set of heuristics to guess involved muscle groups
  /// and flag simple asymmetries from a single Pose frame.
  static MuscleAdvice analyze(Pose pose) {
    final lm = pose.landmarks;

    // Joint angles
    final leftKnee  = _angle(
      lm[PoseLandmarkType.leftHip],
      lm[PoseLandmarkType.leftKnee],
      lm[PoseLandmarkType.leftAnkle],
    );
    final rightKnee = _angle(
      lm[PoseLandmarkType.rightHip],
      lm[PoseLandmarkType.rightKnee],
      lm[PoseLandmarkType.rightAnkle],
    );

    final leftElbow  = _angle(
      lm[PoseLandmarkType.leftShoulder],
      lm[PoseLandmarkType.leftElbow],
      lm[PoseLandmarkType.leftWrist],
    );
    final rightElbow = _angle(
      lm[PoseLandmarkType.rightShoulder],
      lm[PoseLandmarkType.rightElbow],
      lm[PoseLandmarkType.rightWrist],
    );

    // Hip angle on one side (proxy for hip hinge depth)
    final hipAngle = _angle(
      lm[PoseLandmarkType.leftShoulder],
      lm[PoseLandmarkType.leftHip],
      lm[PoseLandmarkType.leftKnee],
    );

    final focus = <String>[];
    final caution = <String>[];

    // Heuristics
    // Deep knee flexion suggests squat/knee-dominant work → quads/glutes.
    if ((leftKnee ?? 999) < 100 || (rightKnee ?? 999) < 100) {
      focus.add('Quads/Glutes');
    }

    // Elbow flexion suggests arm work; include shoulders as stabilizers.
    if ((leftElbow ?? 999) < 100 || (rightElbow ?? 999) < 100) {
      focus.add('Biceps/Triceps & Shoulders');
    }

    // Smaller hip angle → more hinge → posterior chain.
    if (hipAngle != null && hipAngle < 120) {
      focus.add('Glutes/Hamstrings (hinge)');
    }

    // Simple asymmetry checks.
    if (leftKnee != null && rightKnee != null &&
        (leftKnee - rightKnee).abs() > 12) {
      caution.add('Knee symmetry (shift weight evenly)');
    }
    if (leftElbow != null && rightElbow != null &&
        (leftElbow - rightElbow).abs() > 12) {
      caution.add('Arm symmetry (keep elbows even)');
    }

    final summary = [
      if (focus.isEmpty)
        'No clear contraction pattern — try holding a representative pose.',
      if (focus.isNotEmpty) 'Likely working: ${focus.toSet().join(", ")}.',
      if (caution.isNotEmpty) 'Watch out: ${caution.join(", ")}.'
    ].join(' ');

    return MuscleAdvice(
      focus: focus.toSet().toList(),
      caution: caution,
      summary: summary,
    );
  }
}

