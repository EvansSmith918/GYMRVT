// lib/pages/photo_advisor_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../widgets/pose_painter.dart';
import '../services/muscle_advisor.dart';

class PhotoAdvisorPage extends StatefulWidget {
  const PhotoAdvisorPage({super.key});
  @override
  State<PhotoAdvisorPage> createState() => _PhotoAdvisorPageState();
}

class _PhotoAdvisorPageState extends State<PhotoAdvisorPage> {
  final ImagePicker _picker = ImagePicker();
  late final PoseDetector _detector;

  File? _file;
  Size? _imgSize;
  List<Pose> _poses = const [];
  MuscleAdvice? _advice;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );
  }

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  Future<ui.Image> _decode(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => c.complete(img));
    return c.future;
  }

  Future<void> _pickAndAnalyze() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    setState(() {
      _busy = true;
      _file = File(x.path);
      _poses = const [];
      _advice = null;
      _imgSize = null;
    });

    try {
      final bytes = await _file!.readAsBytes();
      final uiImg = await _decode(bytes);
      _imgSize = Size(uiImg.width.toDouble(), uiImg.height.toDouble());

      // Try pose (optional)
      final input = InputImage.fromFile(_file!);
      final poses = await _detector.processImage(input);
      _poses = poses;

      // Advice driven by your **training history**; pose adds small posture notes.
      _advice = await MuscleAdvisor.analyze(pose: poses.isNotEmpty ? poses.first : null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Advisor'),
        actions: [
          IconButton(
            tooltip: 'Pick photo',
            onPressed: _busy ? null : _pickAndAnalyze,
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _pickAndAnalyze,
        icon: const Icon(Icons.photo),
        label: const Text('Choose Photo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_file == null) _emptyHint() else _imageWithOverlay(),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          _adviceCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _emptyHint() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.photo_library, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Upload a full-body photo. We’ll use your recent training to suggest\n'
            'which muscle groups likely need more work—and which may be fatigued.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickAndAnalyze,
            icon: const Icon(Icons.photo),
            label: const Text('Pick from gallery'),
          ),
        ],
      ),
    );
  }

  Widget _imageWithOverlay() {
    final s = _imgSize;
    if (s == null) return const SizedBox.shrink();
    final ar = s.width / s.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: ar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_file!, fit: BoxFit.contain),
            if (_poses.isNotEmpty)
              CustomPaint(
                painter: PosePainter(poses: _poses, imageSize: s, repCount: 0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adviceCard() {
    final a = _advice;
    if (_file == null) return const SizedBox.shrink();

    if (a == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.insights_outlined),
              SizedBox(width: 12),
              Expanded(child: Text('No advice yet. Pick a photo to analyze.')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Muscle Advisor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(a.summary),
            const SizedBox(height: 12),
            if (a.focus.isNotEmpty) ...[
              const Text('Needs more work', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: a.focus.map((g) => Chip(label: Text(g))).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (a.caution.isNotEmpty) ...[
              const Text('Potentially fatigued', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...a.caution.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.warning_amber_rounded, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(c)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
