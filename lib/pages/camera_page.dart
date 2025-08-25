import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../services/camera_stream.dart';
import '../services/pose_mlkit.dart';
import '../services/ema_filter.dart';
import '../services/rep_counter.dart';
import '../models/exercise_profile.dart';
import '../models/rep_event.dart';
import '../widgets/pose_painter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _cam = CameraStream();
  late final PoseMlKit _pose;
  final _yFilter = EmaFilter(alpha: 0.25);
  late final RepCounter _counter;

  List<Pose> _poses = const [];
  Size _imageSize = const Size(720, 1280);
  int _reps = 0;
  DateTime? _lastTs;
  double? _lastY;

  bool get _isFront =>
      _cam.controller?.description.lensDirection == CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _pose = PoseMlKit(accurate: false);
    _counter = RepCounter(ExerciseProfile.squatDefault);
    _boot();
  }

  Future<void> _boot() async {
    await _cam.init(preferred: CameraLensDirection.back);
    if (!mounted) return;
    setState(() {});
    await _cam.start(_onImage);
  }

  Future<void> _flipCamera() async {
    await _cam.switchCamera();
    if (!mounted) return;
    setState(() {});
    // restart stream with new controller
    await _cam.start(_onImage);
  }

  Future<void> _onImage(CameraImage img) async {
    if (!mounted || _cam.controller == null) return;
    final camDesc = _cam.controller!.description;
    _imageSize = Size(img.width.toDouble(), img.height.toDouble());

    // Run ML Kit pose
    final poses = await _pose.process(img, camDesc);
    if (!mounted) return;

    // vertical motion proxy from hips (normalized 0..1)
    double? proxyY;
    if (poses.isNotEmpty) {
      final lm = poses.first.landmarks;
      final lh = lm[PoseLandmarkType.leftHip]?.y;
      final rh = lm[PoseLandmarkType.rightHip]?.y;
      if (lh != null && rh != null) {
        proxyY = (lh + rh) / 2.0;
        proxyY = (proxyY / _imageSize.height).clamp(0.0, 1.0);
      }
    }

    if (proxyY != null) {
      final t = DateTime.now();
      final y = _yFilter.filter(proxyY);
      double vel = 0.0;
      if (_lastTs != null && _lastY != null) {
        final dt = t.difference(_lastTs!).inMilliseconds / 1000.0;
        if (dt > 0) vel = (y - _lastY!) / dt;
      }
      _lastTs = t;
      _lastY = y;

      final RepEvent? evt = _counter.update(y, vel, t);
      if (evt != null) {
        setState(() => _reps += 1);
        // hook into your store/logger here if desired
      }
    }

    setState(() => _poses = poses);
  }

  @override
  void dispose() {
    _cam.dispose();
    _pose.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _cam.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera • Live Pose'),
        actions: [
          IconButton(
            tooltip: 'Flip camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: _cam.isReady ? _flipCamera : null,
          ),
        ],
      ),
      body: (!(_cam.isReady) || ctrl == null)
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (_, __) {
                // Camera gives a landscape previewSize; swap for portrait box.
                final preview = ctrl.value.previewSize!;
                final displaySize =
                    Size(preview.height, preview.width); // swap for portrait

                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain, // keep aspect ratio, fill as much as possible
                    child: SizedBox(
                      width: displaySize.width,
                      height: displaySize.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(ctrl),
                          CustomPaint(
                            painter: PosePainter(
                              poses: _poses,
                              imageSize: _imageSize,
                              repCount: _reps,
                              isFrontCamera: _isFront,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

