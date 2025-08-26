// lib/services/nutrition_store.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

  static FoodItem fromRow(Map<String, Object?> r) => FoodItem(
        id: r['id'] as int?,
        name: r['name'] as String,
        brand: r['brand'] as String?,
        barcode: r['barcode'] as String?,
        servingSizeGram: (r['serving_size_g'] as num).toDouble(),
        cals: (r['cals'] as num).toDouble(),
        protein: (r['protein'] as num).toDouble(),
        carbs: (r['carbs'] as num).toDouble(),
        fat: (r['fat'] as num).toDouble(),
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
}

class NutritionStore {
  static final NutritionStore _i = NutritionStore._();
  NutritionStore._();
  factory NutritionStore() => _i;

  Database? _db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'nutrition.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE food_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand TEXT,
            barcode TEXT,
            serving_size_g REAL NOT NULL,
            cals REAL NOT NULL,
            protein REAL NOT NULL,
            carbs REAL NOT NULL,
            fat REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meal_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_id INTEGER NOT NULL,
            servings REAL NOT NULL,
            logged_at TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            FOREIGN KEY(food_id) REFERENCES food_items(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE nutrition_target(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            daily_cals INTEGER NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL
          )
        ''');
        await db.insert('nutrition_target', {
          'id': 1,
          'daily_cals': 2600,
          'protein_g': 175.0,
          'carbs_g': 280.0,
          'fat_g': 80.0,
        });
      },
    );
  }

  Database get db => _db!;

  // --- Foods ---
  Future<int> upsertFood(FoodItem f) async {
    if (f.id == null) {
      return db.insert('food_items', f.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update('food_items', f.toMap(),
          where: 'id = ?', whereArgs: [f.id]);
      return f.id!;
    }
  }

  Future<List<FoodItem>> searchFoods(String q) async {
    final rows = await db.query('food_items',
        where: 'name LIKE ? OR brand LIKE ? OR barcode = ?',
        whereArgs: ['%$q%', '%$q%', q]);
    return rows.map(FoodItem.fromRow).toList();
  }

  Future<FoodItem?> foodByBarcode(String code) async {
    final rows = await db.query('food_items',
        where: 'barcode = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) return null;
    return FoodItem.fromRow(rows.first);
  }

  // --- Meals ---
  Future<int> logMeal(MealEntry e) => db.insert('meal_entries', e.toMap());

  Future<List<Map<String, dynamic>>> dayEntries(DateTime day) async {
    final s = DateTime(day.year, day.month, day.day);
    final e = s.add(const Duration(days: 1));
    return db.rawQuery('''
      SELECT m.id as meal_id, m.servings, m.logged_at, m.meal_type,
             f.*
      FROM meal_entries m
      JOIN food_items f ON f.id = m.food_id
      WHERE m.logged_at >= ? AND m.logged_at < ?
      ORDER BY m.logged_at DESC
    ''', [s.toIso8601String(), e.toIso8601String()]);
  }

  String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // --- Targets ---
  Future<Map<String, num>> getTargets() async {
    final r = await db.query('nutrition_target', where: 'id = 1', limit: 1);
    final m = r.first;
    return {
      'cals': m['daily_cals'] as int,
      'protein': (m['protein_g'] as num),
      'carbs': (m['carbs_g'] as num),
      'fat': (m['fat_g'] as num),
    };
  }

  Future<void> setTargets({
    required int cals,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    await db.update('nutrition_target', {
      'daily_cals': cals,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
    }, where: 'id = 1');
  }
}
