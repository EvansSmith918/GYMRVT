import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymrvt/services/appearance_prefs.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});
  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final controller = AppearanceController();
  Color _temp = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  Future<void> _pickColor() async {
    _temp = controller.model.color;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick background color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _temp,
            onColorChanged: (c) => _temp = c,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await controller.setColor(_temp);
              if (ctx.mounted) Navigator.pop(ctx);     //  guard the dialog context, not State.context
              setState(() {});                          // refresh preview if any
            },
            child: const Text('Use color'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) {
      await controller.setImagePath(x.path);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _reset() async {
    await controller.clearBackground();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final m = controller.model;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Background color'),
              subtitle: Text('#${m.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}'),
              trailing: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(6)),
              ),
              onTap: _pickColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Background image'),
              subtitle: Text(m.imagePath ?? 'None'),
              trailing: const Icon(Icons.photo_library_outlined),
              onTap: _pickImage,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to default'),
          ),
        ],
      ),
    );
  }
}
