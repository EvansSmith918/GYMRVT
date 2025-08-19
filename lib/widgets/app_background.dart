import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymrvt/services/appearance_prefs.dart';

/// Renders the globally selected background (color or image) behind [child].
/// Rebuilds automatically when the user changes it in Profile.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final prefs = AppearancePrefs(); // singleton + ChangeNotifier
    return AnimatedBuilder(
      animation: prefs,
      builder: (BuildContext _, __) {
        final s = prefs.state;

        Widget bg;
        if (s.type == BgType.image && s.imagePath != null && File(s.imagePath!).existsSync()) {
          bg = Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(s.imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          );
        } else {
          bg = Container(color: s.color);
        }

        // Slight dark overlay for legibility on bright images/colors
        final overlay = Container(color: Colors.black.withOpacity(0.12));

        return Stack(
          fit: StackFit.expand,
          children: [bg, overlay, child],
        );
      },
    );
  }
}
