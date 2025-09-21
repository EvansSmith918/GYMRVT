import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nutrition_store.dart';

class FoodLookup {
  static Future<FoodItem?> byBarcode(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final j = jsonDecode(res.body);
    final p = j['product'];
    if (p == null) return null;
    final n = p['nutriments'] ?? {};

    double parseNum(dynamic x) {
      if (x == null) return 0;
      if (x is num) return x.toDouble();
      if (x is String) {
        return double.tryParse(x.replaceAll(RegExp('[^0-9\\.]'), '')) ?? 0;
      }
      return 0;
    }

    return FoodItem(
      name: (p['product_name'] ?? p['generic_name'] ?? 'Unknown').toString(),
      brand: (p['brands'] ?? '').toString(),
      barcode: barcode,
      servingSizeGram:
          parseNum(n['serving_size']) == 0 ? 100 : parseNum(n['serving_size']),
      cals: parseNum(n['energy-kcal_serving'] ?? n['energy-kcal_100g']),
      protein: parseNum(n['proteins_serving'] ?? n['proteins_100g']),
      carbs: parseNum(n['carbohydrates_serving'] ?? n['carbohydrates_100g']),
      fat: parseNum(n['fat_serving'] ?? n['fat_100g']),
    );
  }
}
