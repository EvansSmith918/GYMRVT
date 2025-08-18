import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { lb, kg }

class UserPrefs {
  static const _unitKey = 'unit';
  static const _restKey = 'rest_seconds';
  static const _barLbKey = 'bar_lb';
  static const _barKgKey = 'bar_kg';
  static const lbPerKg = 2.20462262185;

  static Future<SharedPreferences> get _p async => SharedPreferences.getInstance();

  // Units
  static Future<WeightUnit> unit() async {
    final p = await _p;
    final s = p.getString(_unitKey);
    return s == 'kg' ? WeightUnit.kg : WeightUnit.lb;
  }

  static Future<void> setUnit(WeightUnit u) async {
    final p = await _p;
    await p.setString(_unitKey, u == WeightUnit.kg ? 'kg' : 'lb');
  }

  // Conversion helpers
  static double toDisplay(double lb, WeightUnit u) => u == WeightUnit.lb ? lb : lb / lbPerKg;
  static double fromDisplay(double v, WeightUnit u) => u == WeightUnit.lb ? v : v * lbPerKg;

  // Rest timer
  static Future<int> restSeconds() async {
    final p = await _p;
    return p.getInt(_restKey) ?? 90;
  }

  static Future<void> setRestSeconds(int s) async {
    final p = await _p;
    await p.setInt(_restKey, s);
  }

  // Bar weight (defaults: 45 lb / 20 kg)
  static Future<double> barWeight(WeightUnit u) async {
    final p = await _p;
    return u == WeightUnit.lb ? (p.getDouble(_barLbKey) ?? 45.0) : (p.getDouble(_barKgKey) ?? 20.0);
  }

  static Future<void> setBarWeight(WeightUnit u, double w) async {
    final p = await _p;
    if (u == WeightUnit.lb) {
      await p.setDouble(_barLbKey, w);
    } else {
      await p.setDouble(_barKgKey, w);
    }
  }

  // Quick weight chips
  static List<double> weightChips(WeightUnit u) =>
      u == WeightUnit.lb ? [45, 95, 135, 185, 225] : [20, 40, 60, 80, 100];
}
