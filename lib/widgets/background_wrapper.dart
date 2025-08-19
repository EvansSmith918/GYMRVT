import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymrvt/services/appearance_prefs.dart';

/// Paints the user-selected background behind [child].
/// Works with both solid color and full-screen image.
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final prefs = AppearancePrefs();
    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) {
        final s = prefs.state;

        DecorationImage? image;
        if (s.type == BgType.image &&
            s.imagePath != null &&
            File(s.imagePath!).existsSync()) {
          image = DecorationImage(
            image: FileImage(File(s.imagePath!)),
            fit: BoxFit.cover,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: s.type == BgType.color ? s.color : null,
            image: image,
          ),
          child: child,
        );
      },
    );
  }
}
