import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final int repCount;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.repCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final xScale = size.width / imageSize.width;
    final yScale = size.height / imageSize.height;

    final joint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final bone = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Colors.white;

    for (final p in poses) {
      final lm = p.landmarks;

      void dot(PoseLandmarkType t) {
        final l = lm[t];
        if (l == null) return;
        canvas.drawCircle(Offset(l.x * xScale, l.y * yScale), 2.0, joint);
      }

      void line(PoseLandmarkType a, PoseLandmarkType b) {
        final la = lm[a];
        final lb = lm[b];
        if (la == null || lb == null) return;
        canvas.drawLine(
          Offset(la.x * xScale, la.y * yScale),
          Offset(lb.x * xScale, lb.y * yScale),
          bone,
        );
      }

      line(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      line(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      line(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      line(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      line(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      line(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      line(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      line(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      line(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      line(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

      for (final t in lm.keys) {
        dot(t);
      }
    }

    final tp = TextPainter(
      text: TextSpan(
        text: 'Reps: $repCount',
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(12, 12));
  }

  @override
  bool shouldRepaint(covariant PosePainter old) =>
      old.poses != poses || old.repCount != repCount || old.imageSize != imageSize;
}

