import 'api_service.dart';

class FoodDatabase {
  static const Map<String, int> commonCalories = {
    'oats': 150,
    'oatmeal': 150,
    'egg': 70,
    'eggs': 140,
    'boiled egg': 70,
    'omelette': 160,
    'toast': 80,
    'bread': 80,
    'tea': 40,
    'coffee': 50,
    'milk': 120,
    'poha': 180,
    'upma': 200,
    'idli': 90,
    'dosa': 170,
    'paratha': 260,
    'apple': 95,
    'banana': 105,
    'fruits': 100,
    'cereal': 130,
    'pancakes': 220,
    'rice': 200,
    'brown rice': 210,
    'roti': 100,
    'chapati': 100,
    'dal': 150,
    'paneer': 260,
    'chicken': 240,
    'chicken curry': 280,
    'salad': 60,
    'curd': 90,
    'yogurt': 100,
    'rajma': 240,
    'chole': 250,
    'subzi': 120,
    'vegetables': 100,
    'sandwich': 250,
    'khichdi': 220,
    'soup': 90,
    'fish': 200,
    'pasta': 280,
    'wrap': 260,
    'grilled chicken': 220,
    'sprouts': 80,
  };

  /// Parses text like "2 roti, dal, rice" and calculates total calories locally
  static int calculateCalories(String input) {
    if (input.trim().isEmpty) return 0;
    int total = 0;
    final items = input.split(RegExp(r'[,+]'));
    for (var item in items) {
      final clean = item.trim().toLowerCase();
      if (clean.isEmpty) continue;

      final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(clean);
      int quantity = 1;
      String foodName = clean;
      if (match != null) {
        quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        foodName = match.group(2)?.trim() ?? clean;
      }

      int? cal = commonCalories[foodName];
      if (cal == null) {
        for (var entry in commonCalories.entries) {
          if (foodName.contains(entry.key) || entry.key.contains(foodName)) {
            cal = entry.value;
            break;
          }
        }
      }
      cal ??= 120;
      total += (cal * quantity);
    }
    return total;
  }

  /// Calculates meal calories using backend MongoDB API with local fallback
  static Future<int> calculateViaApi(String input) async {
    return ApiService().calculateMealCalories(input);
  }
}
