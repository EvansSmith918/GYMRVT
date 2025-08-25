import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Paints ML Kit pose landmarks/skeleton on top of an image rendered with
/// BoxFit.contain inside [drawRect].
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize; // original pixel size of the analyzed image
  final Rect drawRect;  // where the image is shown on canvas
  final bool flipX;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.drawRect,
    this.flipX = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final sx = drawRect.width / imageSize.width;
    final sy = drawRect.height / imageSize.height;

    final joint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    final jointShadow = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(.35);
    final bone = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.95);
    final boneShadow = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(.35);

    Offset mapPoint(PoseLandmark l) {
      var x = l.x * sx + drawRect.left;
      if (flipX) {
        final rel = l.x * sx;
        x = drawRect.left + (drawRect.width - rel);
      }
      final y = l.y * sy + drawRect.top;
      return Offset(x, y);
    }

    void line(Map<PoseLandmarkType, PoseLandmark> lm,
        PoseLandmarkType a, PoseLandmarkType b) {
      final la = lm[a];
      final lb = lm[b];
      if (la == null || lb == null) return;
      final pa = mapPoint(la);
      final pb = mapPoint(lb);
      canvas.drawLine(pa, pb, boneShadow);
      canvas.drawLine(pa, pb, bone);
    }

    void dot(PoseLandmark l) {
      final p = mapPoint(l);
      canvas.drawCircle(p, 4.5, jointShadow);
      canvas.drawCircle(p, 3.0, joint);
    }

    for (final pose in poses) {
      final lm = pose.landmarks;

      // Torso
      line(lm, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      line(lm, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      line(lm, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      line(lm, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

      // Arms
      line(lm, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      line(lm, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      line(lm, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      line(lm, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Legs
      line(lm, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      line(lm, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      line(lm, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      line(lm, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

      // Dots
      for (final l in lm.values) {
        dot(l);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) =>
      oldDelegate.poses != poses ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.drawRect != drawRect ||
      oldDelegate.flipX != flipX;
}
