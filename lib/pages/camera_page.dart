// lib/pages/camera_page.dart
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
import '../services/muscle_advisor.dart'; // <-- use MuscleAdvice/MuscleAdvisor

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

  @override
  void initState() {
    super.initState();
    _pose = PoseMlKit(accurate: false);
    _counter = RepCounter(ExerciseProfile.squatDefault);
    _boot();
  }

  Future<void> _boot() async {
    await _cam.init(); // Back camera, YUV, high res
    if (!mounted) return;
    setState(() {});
    await _cam.start(_onImage);
  }

  Future<void> _onImage(CameraImage img) async {
    if (!mounted || _cam.controller == null) return;
    final camDesc = _cam.controller!.description;
    _imageSize = Size(img.width.toDouble(), img.height.toDouble());

    // Run ML Kit pose
    final poses = await _pose.process(img, camDesc);
    if (!mounted) return;

    // Choose a robust proxy for vertical motion (hips work well for squats)
    double? proxyY;
    if (poses.isNotEmpty) {
      final lm = poses.first.landmarks;
      final lh = lm[PoseLandmarkType.leftHip]?.y;
      final rh = lm[PoseLandmarkType.rightHip]?.y;
      if (lh != null && rh != null) {
        proxyY = (lh + rh) / 2.0;
        // normalize 0..1 (0 top, 1 bottom)
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
        setState(() {
          _reps += 1;
        });
      }
    }

    setState(() {
      _poses = poses;
    });
  }

  @override
  void dispose() {
    _cam.dispose();
    _pose.close();
    super.dispose();
  }

  Future<void> _analyzeCurrentPose() async {
    if (_poses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pose detected. Hold a steady pose and try again.')),
      );
      return;
    }
    final MuscleAdvice advice = MuscleAdvisor.analyze(_poses.first);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Muscle Advisor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(advice.summary),
              const SizedBox(height: 12),
              if (advice.focus.isNotEmpty) ...[
                const Text('Focus', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: advice.focus
                      .map((m) => Chip(label: Text(m)))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              if (advice.caution.isNotEmpty) ...[
                const Text('Caution', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...advice.caution.map((c) => Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(c)),
                      ],
                    )),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  // Optional: only works if your CameraStream has switchCamera()
  Future<void> _tryFlipCamera() async {
    if (!_cam.isReady) return;
    final hasSwitch =
        _cam.runtimeType.toString() == 'CameraStream' &&
        _cam
            .toString()
            .contains('switchCamera'); // very loose detection to avoid crashes
    if (!hasSwitch) return;
    try {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      // If you added switchCamera() per previous suggestion, call it:
      // await _cam.switchCamera();
    } catch (_) {
      // silently ignore if not implemented
    }
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
            onPressed: _tryFlipCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: (!(_cam.isReady) || ctrl == null)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(ctrl),
                CustomPaint(
                  painter: PosePainter(
                    poses: _poses,
                    imageSize: _imageSize,
                    repCount: _reps,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzeCurrentPose,
        icon: const Icon(Icons.insights),
        label: const Text('Analyze'),
      ),
    );
  }
}
