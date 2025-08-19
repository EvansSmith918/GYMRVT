import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BgType { color, image }

class AppearanceState {
  final BgType type;
  final Color color;
  final String? imagePath;

  const AppearanceState({
    required this.type,
    required this.color,
    this.imagePath,
  });

  AppearanceState copyWith({BgType? type, Color? color, String? imagePath}) {
    return AppearanceState(
      type: type ?? this.type,
      color: color ?? this.color,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color': color.value,
        'imagePath': imagePath,
      };

  factory AppearanceState.fromJson(Map<String, dynamic> json) {
    final t = (json['type'] as String?) ?? 'color';
    return AppearanceState(
      type: t == 'image' ? BgType.image : BgType.color,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFF101010),
      imagePath: json['imagePath'] as String?,
    );
  }
}

/// Singleton app-wide appearance controller (persists + notifies).
class AppearancePrefs extends ChangeNotifier {
  static const _key = 'appearance_v1';

  AppearancePrefs._internal() {
    _load();
  }
  static final AppearancePrefs _instance = AppearancePrefs._internal();
  factory AppearancePrefs() => _instance;

  AppearanceState _state =
      const AppearanceState(type: BgType.color, color: Color(0xFF101010));

  AppearanceState get state => _state;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _state = AppearanceState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {/* keep defaults */}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_state.toJson()));
  }

  Future<void> setColor(Color c) async {
    _state = _state.copyWith(type: BgType.color, color: c, imagePath: null);
    await _save();
    notifyListeners();
  }

  Future<void> setImage(String path) async {
    _state = _state.copyWith(type: BgType.image, imagePath: path);
    await _save();
    notifyListeners();
  }

  Future<void> useColorMode() async {
    _state = _state.copyWith(type: BgType.color, imagePath: null);
    await _save();
    notifyListeners();
  }
}
