import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:gymrvt/services/appearance_prefs.dart';
import 'package:gymrvt/widgets/app_background.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final AppearancePrefs _prefs = AppearancePrefs();

  Future<void> _pickBgColor() async {
    Color tmp = _prefs.state.color;
    final picked = await showDialog<Color?>(
      context: this.context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Background color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: tmp,
            onColorChanged: (c) => tmp = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, tmp),
            child: const Text('Use color'),
          ),
        ],
      ),
    );
    if (picked != null) {
      await _prefs.setColor(picked);
    }
  }

  Future<void> _pickBgImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fname = 'bg_${DateTime.now().millisecondsSinceEpoch}${extension(x.path)}';
    final saved = await File(x.path).copy('${dir.path}/$fname');
    await _prefs.setImage(saved.path);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Appearance'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AnimatedBuilder(
          animation: _prefs,
          builder: (BuildContext context, _) {
            final s = _prefs.state;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.type == BgType.color
                                ? 'Using background color'
                                : (s.imagePath != null ? 'Using background image' : 'No image set'),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickBgColor,
                          icon: const Icon(Icons.palette),
                          label: const Text('Color'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _pickBgImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Image'),
                        ),
                        const SizedBox(width: 8),
                        if (s.type == BgType.image)
                          TextButton(
                            onPressed: _prefs.useColorMode,
                            child: const Text('Use color'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (s.type == BgType.image && s.imagePath != null && File(s.imagePath!).existsSync())
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(File(s.imagePath!), height: 160, fit: BoxFit.cover),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
