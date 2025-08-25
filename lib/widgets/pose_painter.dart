import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;      // Size from CameraImage (sensor coords)
  final int repCount;
  final bool isFrontCamera;  // <-- NEW: mirror overlay when using front cam

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.repCount,
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // In portrait, CameraImage is landscape (w,h) but preview is rotated 90°.
    // Map (x,y) from image -> preview by SWAPPING axes and scaling.
    // image:  (x across width, y across height)
    // preview:(dx across width)  uses image y
    //         (dy across height) uses image x
    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    Offset _map(double x, double y) {
      // swap axes
      double dx = y * scaleX;
      double dy = x * scaleY;

      // mirror for front camera
      if (isFrontCamera) dx = size.width - dx;
      return Offset(dx, dy);
    }

    final joint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;

    final bone = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;

    for (final p in poses) {
      final lm = p.landmarks;

      void dot(PoseLandmarkType t) {
        final l = lm[t];
        if (l == null) return;
        canvas.drawCircle(_map(l.x, l.y), 2.0, joint);
      }

      void line(PoseLandmarkType a, PoseLandmarkType b) {
        final la = lm[a], lb = lm[b];
        if (la == null || lb == null) return;
        canvas.drawLine(_map(la.x, la.y), _map(lb.x, lb.y), bone);
      }

      // minimal skeleton
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

    // Reps label
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
      old.poses != poses ||
      old.repCount != repCount ||
      old.imageSize != imageSize ||
      old.isFrontCamera != isFrontCamera;
}
