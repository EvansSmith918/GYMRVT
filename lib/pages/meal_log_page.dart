// lib/pages/meal_log_page.dart
import 'package:flutter/material.dart';
import '../services/nutrition_store.dart';
import '../services/food_lookup.dart';
import 'scan_barcode_page.dart';

class MealLogPage extends StatefulWidget {
  const MealLogPage({super.key});
  @override
  State<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends State<MealLogPage> {
  final _q = TextEditingController();
  List<FoodItem> _results = [];
  double _servings = 1.0;
  String _mealType = 'lunch';
  final store = NutritionStore();

  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    final s = await store.searchFoods('Chicken Breast (cooked)');
    if (s.isEmpty) {
      await store.upsertFood(FoodItem(
        name: 'Chicken Breast (cooked)',
        brand: 'Generic',
        barcode: null,
        servingSizeGram: 100,
        cals: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      ));
      await store.upsertFood(FoodItem(
        name: 'Whey Protein Scoop',
        brand: 'Generic',
        barcode: null,
        servingSizeGram: 30,
        cals: 120,
        protein: 24,
        carbs: 3,
        fat: 2,
      ));
      await store.upsertFood(FoodItem(
        name: 'Greek Yogurt (plain, nonfat)',
        brand: 'Generic',
        barcode: null,
        servingSizeGram: 170,
        cals: 100,
        protein: 17,
        carbs: 6,
        fat: 0,
      ));
    }
  }

  Future<void> _search() async {
    final r = await store.searchFoods(_q.text.trim());
    setState(() => _results = r);
  }

  Future<void> _scan() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScanBarcodePage(onScan: (code) async {
        final local = await store.foodByBarcode(code);
        FoodItem? item = local;
        if (item == null) {
          item = await FoodLookup.byBarcode(code);
          if (item != null) {
            final id = await store.upsertFood(item);
            item = FoodItem(
              id: id,
              name: item.name,
              brand: item.brand,
              barcode: item.barcode,
              servingSizeGram: item.servingSizeGram,
              cals: item.cals,
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
            );
          }
        }
        if (!mounted) return;
        if (item == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food not found—add manually.')),
          );
        } else {
          // IMPORTANT: item is non-null here, so assert with !
          setState(() => _results = <FoodItem>[item!]);
        }
      }),
    ));
  }

  Future<void> _log(FoodItem f) async {
    final id = f.id ?? await store.upsertFood(f);
    await store.logMeal(MealEntry(
      foodId: id,
      servings: _servings,
      loggedAt: DateTime.now(),
      mealType: _mealType,
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mealTypes = const ['breakfast', 'lunch', 'dinner', 'snack'];
    return Scaffold(
      appBar: AppBar(title: const Text("Log Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _q,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: "Search foods",
                  suffixIcon:
                      IconButton(onPressed: _search, icon: const Icon(Icons.search)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text("Servings"),
            Expanded(
              child: Slider(
                value: _servings,
                min: 0.25,
                max: 3,
                divisions: 11,
                label: _servings.toStringAsFixed(2),
                onChanged: (v) => setState(() => _servings = v),
              ),
            ),
            DropdownButton<String>(
              value: _mealType,
              items: mealTypes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _mealType = v!),
            ),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Search or scan to find foods'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final f = _results[i];
                      return Card(
                        child: ListTile(
                          title: Text(f.name),
                          subtitle: Text(
                              "${f.brand ?? ''} • ${f.cals.toStringAsFixed(0)} kcal • "
                              "${f.protein.toStringAsFixed(0)}g P • "
                              "${f.carbs.toStringAsFixed(0)}g C • "
                              "${f.fat.toStringAsFixed(0)}g F"),
                          trailing: ElevatedButton(
                              onPressed: () => _log(f),
                              child: const Text("Add")),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

