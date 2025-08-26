// lib/pages/photo_advisor_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gymrvt/services/ai_service.dart';
// If you want to keep drawing landmarks on top, keep this import and painter.
// import 'package:gymrvt/widgets/pose_painter.dart';

class PhotoAdvisorPage extends StatefulWidget {
  const PhotoAdvisorPage({super.key});

  @override
  State<PhotoAdvisorPage> createState() => _PhotoAdvisorPageState();
}

class _PhotoAdvisorPageState extends State<PhotoAdvisorPage> {
  Uint8List? _imgBytes;
  String? _advice;
  bool _loading = false;
  String? _error;

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _error = null;
      _advice = null;
    });

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1600,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _imgBytes = bytes);

    // --- Call AI server ---
    setState(() => _loading = true);
    try {
      final b64 = base64Encode(bytes);
      final advice = await AiService.analyzeBase64(b64);
      setState(() => _advice = advice);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _imgBytes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Photo Advisor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Pick photo',
            icon: const Icon(Icons.image_rounded),
            onPressed: _pickAndAnalyze,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image + overlay container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (img != null)
                      Image.memory(img, fit: BoxFit.contain)
                    else
                      Center(
                        child: Text(
                          'Choose a photo to analyze',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                    if (_loading)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Advice / error card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fitness_center, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Muscle Advisor',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            )
                          else if (_advice != null)
                            Text(_advice!)
                          else
                            const Text(
                              'No analysis yet. Pick a photo and I’ll suggest what may be fatigued and what needs more work.',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Pick photo button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAndAnalyze,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose Photo'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
