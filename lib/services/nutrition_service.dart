// lib/services/nutrition_service.dart
import 'nutrition_store.dart';

class MacroSummary {
  final double cals;
  final double protein;
  final double carbs;
  final double fat;
  const MacroSummary(this.cals, this.protein, this.carbs, this.fat);
}

class NutritionService {
  final NutritionStore store;
  NutritionService(this.store);

  Future<MacroSummary> todaysTotals() async {
    final rows = await store.dayEntries(DateTime.now());
    double c = 0, p = 0, cb = 0, f = 0;
    for (final r in rows) {
      final sv = (r['servings'] as num).toDouble();
      c  += (r['cals'] as num).toDouble()    * sv;
      p  += (r['protein'] as num).toDouble() * sv;
      cb += (r['carbs'] as num).toDouble()   * sv;
      f  += (r['fat'] as num).toDouble()     * sv;
    }
    return MacroSummary(c, p, cb, f);
  }

  String coachLine(MacroSummary t, Map<String, num> target) {
    final dP = (target['protein']! - t.protein).round();
    final dCals = (target['cals']! - t.cals).round();

    if (dP > 60) {
      return "You’re $dP g protein short. Try chicken stir-fry, Greek yogurt, or a whey shake.";
    } else if (dP > 25) {
      return "Add a 25–35 g protein snack to stay on track.";
    }
    if (dCals > 400) {
      return "About $dCals kcal left—plan a balanced meal (protein + carbs + veg).";
    }
    if (dCals < -200) {
      return "Over calories today—go lighter at dinner and bump water/fiber.";
    }
    return "Nice pacing. A lean protein + fruit would be perfect.";
  }
}
