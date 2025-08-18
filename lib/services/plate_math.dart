import 'package:gymrvt/services/user_prefs.dart';

class PlateBreakdown {
  final double target; // display units (lb or kg)
  final double bar;    // display units
  final Map<double, int> perSide; // plate size -> count per side
  final double remainder; // leftover per side (display units)

  PlateBreakdown({
    required this.target,
    required this.bar,
    required this.perSide,
    required this.remainder,
  });

  bool get possible => remainder.abs() < 1e-6 && target >= bar;
}

class PlateMath {
  static const List<double> _lbSizes = [45, 35, 25, 10, 5, 2.5, 1.25];
  static const List<double> _kgSizes = [25, 20, 15, 10, 5, 2.5, 1.25];

  static List<double> defaults(WeightUnit u) =>
      u == WeightUnit.lb ? _lbSizes : _kgSizes;

  /// Compute plate breakdown **per side** in the current display unit.
  static Future<PlateBreakdown> compute({
    required double targetDisplay,
    required WeightUnit unit,
    double? barDisplay, // if null: read from UserPrefs
  }) async {
    final bar = barDisplay ?? await UserPrefs.barWeight(unit);
    final perSide = <double, int>{};
    if (targetDisplay <= bar) {
      return PlateBreakdown(
        target: targetDisplay,
        bar: bar,
        perSide: perSide,
        remainder: 0,
      );
    }

    final plates = defaults(unit);
    double remaining = (targetDisplay - bar) / 2.0; // per side

    for (final size in plates) {
      final count = remaining ~/ size; // floor
      if (count > 0) {
        perSide[size] = count;
        remaining -= count * size;
      }
    }

    // clean tiny FP drift
    remaining = (remaining.abs() < 1e-6) ? 0.0 : remaining;

    return PlateBreakdown(
      target: targetDisplay,
      bar: bar,
      perSide: perSide,
      remainder: remaining,
    );
  }
}

