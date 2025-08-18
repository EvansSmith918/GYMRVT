import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymrvt/services/appearance_prefs.dart';

/// Wraps the whole app (via MaterialApp.builder) or individual pages.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  final controller = AppearanceController();

  @override
  void initState() {
    super.initState();
    // In case not loaded yet; safe to call multiple times.
    controller.load();
    controller.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = controller.model;

    DecorationImage? img;
    if (m.type == BgType.image && m.imagePath != null && m.imagePath!.isNotEmpty) {
      final file = File(m.imagePath!);
      if (file.existsSync()) {
        img = DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: m.type == BgType.color ? m.color : Colors.black,
        image: img,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: widget.child,
      ),
    );
  }
}
