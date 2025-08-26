// lib/pages/photo_advisor_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../widgets/app_background.dart';

class PhotoAdvisorPage extends StatefulWidget {
  const PhotoAdvisorPage({super.key});

  @override
  State<PhotoAdvisorPage> createState() => _PhotoAdvisorPageState();
}

class _PhotoAdvisorPageState extends State<PhotoAdvisorPage> {
  Uint8List? _bytes;
  bool _loading = false;
  String? _error;
  String? _summary;
  List<String> _focus = const [];
  List<String> _caution = const [];

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
    });
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (x == null) return;

    final b = await x.readAsBytes();
    setState(() {
      _bytes = b;
      _summary = null;
      _focus = const [];
      _caution = const [];
    });

    await _sendToAi(b);
  }

  Future<void> _sendToAi(Uint8List bytes) async {
    setState(() => _loading = true);
    try {
      // Simple protocol: your Node server returns a JSON with
      // { advice: string, focus?: string[], caution?: string[] }
      final adviceText = await AiService.analyzeBytes(bytes);

      // Heuristic split: if your server later sends arrays, you can parse them there.
      // For now keep advice as summary and try to extract bullets (optional).
      final focus = <String>[];
      final caution = <String>[];

      // lightweight parse: lines starting with '+' -> focus, '!' -> caution
      for (final line in adviceText.split('\n')) {
        final t = line.trim();
        if (t.startsWith('+')) {
          focus.add(t.substring(1).trim());
        } else if (t.startsWith('!')) {
          caution.add(t.substring(1).trim());
        }
      }

      setState(() {
        _summary = adviceText.isEmpty
            ? 'No advice returned from AI server.'
            : adviceText.split('\n').first.trim();
        _focus = focus;
        _caution = caution;
      });
    } catch (e) {
      setState(() => _error = 'Couldn’t get AI advice: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Photo Advisor'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Choose Photo',
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _heroCard(context),

            const SizedBox(height: 14),
            if (_bytes != null) _imagePreview(),

            if (_loading) ...[
              const SizedBox(height: 14),
              _loadingCard(),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              _errorCard(_error!),
            ],

            if (!_loading && _bytes == null) ...[
              const SizedBox(height: 12),
              _pickCta(context),
            ],

            if (!_loading && _bytes != null && _summary != null) ...[
              const SizedBox(height: 14),
              _adviceCard(),
              const SizedBox(height: 14),
              _secondaryActions(),
            ],
          ],
        ),
      ),
    );
  }

  // --- UI pieces -------------------------------------------------------------

  Widget _heroCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_graph, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Get smart advice from your photo.\n'
              'We look for balance cues (upper/lower, push/pull, core) and combine that with your recent volume to suggest focus areas.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_bytes!, fit: BoxFit.cover),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  _ghostChip('Ready for AI'),
                  const SizedBox(width: 6),
                  if (_loading) _ghostChip('Analyzing…'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _loadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: const [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Analyzing photo with AI…'),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _pickCta(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        child: ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose Photo'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ),
    );
  }

  Widget _adviceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Muscle Advisor'),
            const SizedBox(height: 6),
            if (_summary != null) Text(_summary!, style: const TextStyle(height: 1.3)),

            if (_focus.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SectionTitle('Focus'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _focus
                    .map((m) => Chip(
                          label: Text(m),
                          avatar: const Icon(Icons.add_task, size: 18),
                        ))
                    .toList(),
              ),
            ],

            if (_caution.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SectionTitle('Caution'),
              const SizedBox(height: 6),
              ..._caution.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.warning_amber_rounded, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _secondaryActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Choose Another Photo'),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
