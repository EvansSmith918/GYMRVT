// lib/pages/photo_advisor_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';

class PhotoAdvisorPage extends StatefulWidget {
  const PhotoAdvisorPage({super.key});

  @override
  State<PhotoAdvisorPage> createState() => _PhotoAdvisorPageState();
}

class _PhotoAdvisorPageState extends State<PhotoAdvisorPage> {
  Uint8List? _bytes;
  String? _advice;
  bool _loading = false;

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _bytes = bytes;
      _advice = null;
      _loading = true;
    });

    try {
      final advice = await AiService.analyzeBytes(bytes);
      if (!mounted) return;
      setState(() => _advice = advice);
    } catch (e) {
      if (!mounted) return;
      setState(() => _advice = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photo Advisor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_bytes!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

            if (_loading) const Center(child: CircularProgressIndicator()),

            if (_advice != null && !_loading)
              Card(
                color: Colors.black.withValues(alpha: 0.7),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _advice!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickAndAnalyze,
              icon: const Icon(Icons.photo_library),
              label: Text(_bytes == null ? "Choose Photo" : "Choose Another Photo"),
            ),
          ],
        ),
      ),
    );
  }
}
