// lib/pages/photo_advisor_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../widgets/pose_painter.dart';
import '../services/muscle_advisor.dart';
import '../services/muscle_advisor_api.dart';

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
  MuscleAdvice? _lastAdvice;

  @override
  void initState() {
    super.initState();
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
      _lastAdvice = null;
      _busy = true;
    });

    try {
      // Detect pose (for overlay + local fallback)
      final inputImg = InputImage.fromFilePath(f.path);
      final poses = await _detector!.processImage(inputImg);
      setState(() => _poses = poses);

      // Ask AI (or fall back locally if API_URL is empty/unavailable)
      final advice = await MuscleAdvisorApi.tryAnalyzeOrFallback(
        imageFile: f,
        poseForFallback: poses.isNotEmpty ? poses.first : null,
      );

      if (!mounted) return;
      setState(() => _lastAdvice = advice);

      // Also show as a bottom sheet once (nice UX)
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
          child: _adviceContent(advice, compact: true),
        );
      },
    );
  }

  Widget _adviceContent(MuscleAdvice advice, {bool compact = false}) {
    return Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
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
            children: advice.focus.map((m) => Chip(label: Text(m))).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (advice.caution.isNotEmpty) ...[
          const Text('Caution',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...advice.caution.map((c) => Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c)),
                ],
              )),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: Column(
          children: [
            // Hero/Title
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Get smart advice from your photo',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview card
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.3),
                        theme.colorScheme.surfaceVariant.withOpacity(0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : (_photo == null
                          ? _emptyState(context)
                          : LayoutBuilder(
                              builder: (ctx, c) {
                                final w = c.maxWidth;
                                final h = c.maxHeight;
                                _imageSize = Size(w, h); // match painted area
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_photo!, fit: BoxFit.cover),
                                    if (_poses.isNotEmpty)
                                      CustomPaint(
                                        painter: PosePainter(
                                          poses: _poses,
                                          imageSize: _imageSize,
                                          repCount: 0,
                                        ),
                                      ),
                                    if (_lastAdvice != null)
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: _adviceContent(
                                              _lastAdvice!,
                                              compact: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            )),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _pickPhoto,
                icon: const Icon(Icons.image),
                label: Text(_photo == null ? 'Choose Photo' : 'Choose Another Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          const Text('Add a photo to analyze your form\nand training balance.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.image),
            label: const Text('Choose Photo'),
          ),
        ],
      ),
    );
  }
}

