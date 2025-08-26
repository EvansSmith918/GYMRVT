import 'dart:io';
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
  File? _photo;
  Size _imageSize = const Size(720, 1280);
  List<Pose> _poses = const [];
  PoseDetector? _detector;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Default options — good for still photo analysis
    _detector = PoseDetector(options: PoseDetectorOptions());
  }

  @override
  void dispose() {
    _detector?.close();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final f = File(picked.path);
    setState(() {
      _photo = f;
      _poses = const [];
      _busy = true;
    });

    try {
      final inputImg = InputImage.fromFilePath(f.path);
      final poses = await _detector!.processImage(inputImg);
      setState(() {
        _poses = poses;
      });

      final advice = await MuscleAdvisor.analyze(
        pose: poses.isNotEmpty ? poses.first : null,
      );
      if (!mounted) return;
      _showAdvice(advice);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAdvice(MuscleAdvice advice) {
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
                const Text('Needs more work',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      advice.focus.map((m) => Chip(label: Text(m))).toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (advice.caution.isNotEmpty) ...[
                const Text('Caution',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...advice.caution.map(
                  (c) => Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(c)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _photo == null
        ? const SizedBox.shrink()
        : LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              _imageSize = Size(w, h); // match painted size
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_photo!, fit: BoxFit.cover),
                  CustomPaint(
                    painter: PosePainter(
                      poses: _poses,
                      imageSize: _imageSize,
                      repCount: 0,
                    ),
                  ),
                ],
              );
            },
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Photo Advisor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Pick photo',
            onPressed: _busy ? null : _pickPhoto,
            icon: const Icon(Icons.image_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : (_photo == null
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose Photo'),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: overlay,
                    ),
                  )),
      ),
      bottomNavigationBar: _photo == null
          ? null
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _pickPhoto,
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Photo'),
                ),
              ),
            ),
    );
  }
}

