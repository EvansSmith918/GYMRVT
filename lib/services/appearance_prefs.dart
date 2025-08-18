import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BgType { color, image }

class AppearanceModel {
  final BgType type;
  final Color color;
  final String? imagePath; // local file path from ImagePicker

  const AppearanceModel({
    required this.type,
    required this.color,
    this.imagePath,
  });

  AppearanceModel copyWith({BgType? type, Color? color, String? imagePath}) {
    return AppearanceModel(
      type: type ?? this.type,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
    );
    }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color': color.toARGB32(),
        'imagePath': imagePath,
      };

  factory AppearanceModel.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String? ?? 'color';
    return AppearanceModel(
      type: t == 'image' ? BgType.image : BgType.color,
      color: Color((json['color'] as int?) ?? const Color(0xFF101012).toARGB32()),
      imagePath: json['imagePath'] as String?,
    );
  }

  static const AppearanceModel defaultTheme =
      AppearanceModel(type: BgType.color, color: Color(0xFF101012));
}

class AppearanceController extends ChangeNotifier {
  static const _key = 'appearance_prefs_v1';
  AppearanceModel _model = AppearanceModel.defaultTheme;
  AppearanceModel get model => _model;

  AppearanceController._();
  static final AppearanceController _i = AppearanceController._();
  factory AppearanceController() => _i;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _model = AppearanceModel.fromJson(jsonDecode(raw));
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_model.toJson()));
  }

  Future<void> setColor(Color color) async {
    _model = _model.copyWith(type: BgType.color, color: color, imagePath: null);
    await _save();
    notifyListeners();
  }

  Future<void> setImagePath(String path) async {
    _model = _model.copyWith(type: BgType.image, imagePath: path);
    await _save();
    notifyListeners();
  }

  Future<void> clearBackground() async {
    _model = AppearanceModel.defaultTheme;
    await _save();
    notifyListeners();
  }
}