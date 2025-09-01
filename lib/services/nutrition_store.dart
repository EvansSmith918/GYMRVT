// lib/services/nutrition_store.dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class FoodItem {
  final int? id;
  final String name;
  final String? brand;
  final String? barcode;
  final double servingSizeGram;
  final double cals;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.servingSizeGram,
    required this.cals,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'barcode': barcode,
        'serving_size_g': servingSizeGram,
        'cals': cals,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  static FoodItem fromMap(Map<String, dynamic> m) => FoodItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        brand: m['brand'] as String?,
        barcode: m['barcode'] as String?,
        servingSizeGram: (m['serving_size_g'] as num).toDouble(),
        cals: (m['cals'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        carbs: (m['carbs'] as num).toDouble(),
        fat: (m['fat'] as num).toDouble(),
      );
}

class MealEntry {
  final int? id;
  final int foodId;
  final double servings;
  final DateTime loggedAt;
  final String mealType; // breakfast/lunch/dinner/snack

  MealEntry({
    this.id,
    required this.foodId,
    required this.servings,
    required this.loggedAt,
    required this.mealType,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'food_id': foodId,
        'servings': servings,
        'logged_at': loggedAt.toIso8601String(),
        'meal_type': mealType,
      };

  static MealEntry fromMap(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as int?,
        foodId: m['food_id'] as int,
        servings: (m['servings'] as num).toDouble(),
        loggedAt: DateTime.parse(m['logged_at'] as String),
        mealType: m['meal_type'] as String,
      );
}

class _Store {
  int version;
  int nextFoodId;
  int nextMealId;
  Map<String, num> targets;
  List<FoodItem> foods;
  List<MealEntry> meals;

  _Store({
    required this.version,
    required this.nextFoodId,
    required this.nextMealId,
    required this.targets,
    required this.foods,
    required this.meals,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'nextFoodId': nextFoodId,
        'nextMealId': nextMealId,
        'targets': targets,
        'foods': foods.map((f) => f.toMap()).toList(),
        'meals': meals.map((m) => m.toMap()).toList(),
      };

  static _Store fromJson(Map<String, dynamic> j) => _Store(
        version: j['version'] as int? ?? 1,
        nextFoodId: j['nextFoodId'] as int? ?? 1,
        nextMealId: j['nextMealId'] as int? ?? 1,
        targets: Map<String, num>.from(j['targets'] as Map? ?? {}),
        foods: (j['foods'] as List? ?? [])
            .map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        meals: (j['meals'] as List? ?? [])
            .map((e) => MealEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class NutritionStore {
  static final NutritionStore _i = NutritionStore._();
  NutritionStore._();
  factory NutritionStore() => _i;

  late File _file;
  _Store? _store;
  bool _initializing = false;

  Future<void> init() async {
    if (_store != null || _initializing) return;
    _initializing = true;

    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, 'nutrition.json'));

    if (await _file.exists()) {
      final txt = await _file.readAsString();
      if (txt.trim().isNotEmpty) {
        _store = _Store.fromJson(jsonDecode(txt) as Map<String, dynamic>);
      }
    }

    // First-run defaults
    _store ??= _Store(
      version: 1,
      nextFoodId: 1,
      nextMealId: 1,
      targets: {
        'cals': 2600,
        'protein': 175.0,
        'carbs': 280.0,
        'fat': 80.0,
      },
      foods: [],
      meals: [],
    );

    // Ensure file exists
    if (!await _file.exists()) {
      await _persist();
    }

    _initializing = false;
  }

  _Store get _s {
    final s = _store;
    if (s == null) {
      throw StateError('NutritionStore.init() was not awaited before use.');
    }
    return s;
  }

  Future<void> _persist() async {
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(_s));
    await tmp.rename(_file.path);
  }

  String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // --- Foods (NoSQL style) ---
  Future<int> upsertFood(FoodItem f) async {
    // Update
    if (f.id != null) {
      final idx = _s.foods.indexWhere((x) => x.id == f.id);
      if (idx >= 0) {
        _s.foods[idx] = f;
        await _persist();
        return f.id!;
      }
    }
    // Insert
    final id = _s.nextFoodId++;
    _s.foods.add(FoodItem(
      id: id,
      name: f.name,
      brand: f.brand,
      barcode: f.barcode,
      servingSizeGram: f.servingSizeGram,
      cals: f.cals,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
    ));
    await _persist();
    return id;
  }

  Future<List<FoodItem>> searchFoods(String q) async {
    final qq = q.trim().toLowerCase();
    return _s.foods.where((f) {
      final name = f.name.toLowerCase();
      final brand = (f.brand ?? '').toLowerCase();
      final barcode = (f.barcode ?? '');
      return name.contains(qq) || brand.contains(qq) || barcode == q;
    }).toList();
  }

  Future<FoodItem?> foodByBarcode(String code) async {
    try {
      return _s.foods.firstWhere((f) => (f.barcode ?? '') == code);
    } catch (_) {
      return null;
    }
  }

  // --- Meals ---
  Future<int> logMeal(MealEntry e) async {
    final id = _s.nextMealId++;
    _s.meals.add(MealEntry(
      id: id,
      foodId: e.foodId,
      servings: e.servings,
      loggedAt: e.loggedAt,
      mealType: e.mealType,
    ));
    await _persist();
    return id;
  }

  Future<List<Map<String, dynamic>>> dayEntries(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final meals = _s.meals.where((m) =>
        !m.loggedAt.isBefore(start) && m.loggedAt.isBefore(end));

    final List<Map<String, dynamic>> out = [];
    for (final m in meals) {
      final f = _s.foods.firstWhere((x) => x.id == m.foodId, orElse: () => 
        FoodItem(
          id: -1, name: 'Unknown', brand: null, barcode: null,
          servingSizeGram: 0, cals: 0, protein: 0, carbs: 0, fat: 0));
      out.add({
        'meal_id': m.id,
        'servings': m.servings,
        'logged_at': m.loggedAt.toIso8601String(),
        'meal_type': m.mealType,
        ...f.toMap(),
      });
    }
    // newest first
    out.sort((a, b) => (b['logged_at'] as String)
        .compareTo(a['logged_at'] as String));
    return out;
  }

  // --- Targets ---
  Future<Map<String, num>> getTargets() async => {
        'cals': _s.targets['cals'] ?? 2600,
        'protein': _s.targets['protein'] ?? 175.0,
        'carbs': _s.targets['carbs'] ?? 280.0,
        'fat': _s.targets['fat'] ?? 80.0,
      };

  Future<void> setTargets({
    required int cals,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    _s.targets
      ..['cals'] = cals
      ..['protein'] = protein
      ..['carbs'] = carbs
      ..['fat'] = fat;
    await _persist();
  }
}
