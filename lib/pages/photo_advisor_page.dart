import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../services/muscle_advisor.dart';
import '../widgets/pose_painter.dart';

class PhotoAdvisorPage extends StatefulWidget {
  const PhotoAdvisorPage({super.key});

  @override
  State<PhotoAdvisorPage> createState() => _PhotoAdvisorPageState();
}

class _PhotoAdvisorPageState extends State<PhotoAdvisorPage> {
  Uint8List? _bytes;
  Size _imageSize = Size.zero; // original pixel size
  List<Pose> _poses = const [];
  MuscleAdvice? _advice;
  bool _flipX = false;

  final _picker = ImagePicker();
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.base,
    ),
  );

  @override
  void dispose() {
    _detector.close();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    // Determine original pixel size of the image buffer.
    final codec = await ui.instantiateImageCodec(bytes);
    final fi = await codec.getNextFrame();
    final imgW = fi.image.width.toDouble();
    final imgH = fi.image.height.toDouble();

    // Run pose on the file path.
    final input = InputImage.fromFilePath(picked.path);
    final poses = await _detector.processImage(input);

    // If analyze() uses named params, pass {pose: ...}
    final MuscleAdvice? advice =
        poses.isNotEmpty ? await Future.value(MuscleAdvisor.analyze(pose: poses.first)) : null;

    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _imageSize = Size(imgW, imgH);
      _poses = poses;
      _advice = advice;
    });
  }

  /// Rectangle where the image is actually rendered with BoxFit.contain.
  Rect _containedRect(Size canvas, Size source) {
    if (canvas.isEmpty || source.isEmpty) return Rect.zero;
    final sx = canvas.width / source.width;
    final sy = canvas.height / source.height;
    final scale = sx < sy ? sx : sy;
    final w = source.width * scale;
    final h = source.height * scale;
    final dx = (canvas.width - w) / 2;
    final dy = (canvas.height - h) / 2;
    return Rect.fromLTWH(dx, dy, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Photo Advisor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_bytes != null)
            IconButton(
              tooltip: _flipX ? 'Unflip overlay' : 'Flip overlay',
              onPressed: () => setState(() => _flipX = !_flipX),
              icon: const Icon(Icons.flip),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                final drawRect = _containedRect(canvasSize, _imageSize);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo
                    Container(
                      color: const Color(0xFF1F1C23),
                      child: _bytes == null
                          ? const Center(child: Text('Choose a photo'))
                          : FittedBox(
                              fit: BoxFit.contain,
                              child: Image.memory(_bytes!),
                            ),
                    ),
                    // Overlay
                    if (_bytes != null && _poses.isNotEmpty && !drawRect.isEmpty)
                      CustomPaint(
                        painter: PosePainter(
                          poses: _poses,
                          imageSize: _imageSize,
                          drawRect: drawRect,
                          flipX: _flipX,
                        ),
                        size: Size.infinite,
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Muscle Advisor',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    _advice?.summary ??
                        'Pick a clear, well-lit photo (front or back) Ai-advisor will give advice on certain groups.',
                  ),
                  if (_advice?.focus.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    const Text('Focus',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _advice!.focus
                          .map((m) => Chip(label: Text(m)))
                          .toList(),
                    ),
                  ],
                  if (_advice?.caution.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    const Text('Caution',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ..._advice!.caution.map(
                      (c) => Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(c)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
