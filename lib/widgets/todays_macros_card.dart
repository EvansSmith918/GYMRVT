// lib/widgets/todays_macros_card.dart
import 'package:flutter/material.dart';
import '../services/nutrition_store.dart';
import '../services/nutrition_service.dart';
import '../pages/meal_log_page.dart';

class TodaysMacrosCard extends StatefulWidget {
  const TodaysMacrosCard({super.key});

  @override
  State<TodaysMacrosCard> createState() => _TodaysMacrosCardState();
}

class _TodaysMacrosCardState extends State<TodaysMacrosCard> {
  final store = NutritionStore();
  late final NutritionService service = NutritionService(store);
  MacroSummary? totals;
  Map<String, num>? target;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await service.todaysTotals();
    final g = await store.getTargets();
    setState(() { totals = t; target = g; });
  }

  @override
  Widget build(BuildContext context) {
    final t = totals;
    final g = target;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: t == null || g == null
            ? const Text("Loading nutrition…")
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: const [
                    Icon(Icons.restaurant, size: 18),
                    SizedBox(width: 6),
                    Text("Today’s Macros", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                _row("Calories", "${t.cals.toStringAsFixed(0)} / ${(g['cals']!).toStringAsFixed(0)} kcal"),
                _row("Protein",  "${t.protein.toStringAsFixed(0)} / ${(g['protein']!).toStringAsFixed(0)} g"),
                _row("Carbs",    "${t.carbs.toStringAsFixed(0)} / ${(g['carbs']!).toStringAsFixed(0)} g"),
                _row("Fat",      "${t.fat.toStringAsFixed(0)} / ${(g['fat']!).toStringAsFixed(0)} g"),
                const SizedBox(height: 8),
                Text(service.coachLine(t, g)),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MealLogPage()));
                      if (mounted) _load();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Log meal"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await store.setTargets(
                        cals: (g['cals'] as num).toInt(),
                        protein: (g['protein'] as num).toDouble() + 10.0,
                        carbs: (g['carbs'] as num).toDouble(),
                        fat: (g['fat'] as num).toDouble(),
                      );
                      if (mounted) _load();
                    },
                    child: const Text("+10g protein target"),
                  ),
                ]),
              ]),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))]),
  );
}
