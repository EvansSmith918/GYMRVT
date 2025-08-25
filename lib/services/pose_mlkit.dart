import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMlKit {
  late final PoseDetector _detector;
  bool _busy = false;

  PoseMlKit({bool accurate = false}) {
    // Broadly compatible options
    _detector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  Future<List<Pose>> process(CameraImage img, CameraDescription cam) async {
    if (_busy) return const [];
    _busy = true;
    try {
      final bytes = _concatPlanes(img.planes);

      final metadata = InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(cam.sensorOrientation)
            ?? InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: img.planes.first.bytesPerRow,
      );

      final input = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      return await _detector.processImage(input);
    } finally {
      _busy = false;
    }
  }

  // Manual concat — avoids WriteBuffer/dart:ui
  Uint8List _concatPlanes(List<Plane> planes) {
    final totalLength = planes.fold<int>(0, (sum, p) => sum + p.bytes.length);
    final bytes = Uint8List(totalLength);
    var offset = 0;
    for (final p in planes) {
      bytes.setAll(offset, p.bytes);
      offset += p.bytes.length;
    }
    return bytes;
  }

  Future<void> close() => _detector.close();
}
