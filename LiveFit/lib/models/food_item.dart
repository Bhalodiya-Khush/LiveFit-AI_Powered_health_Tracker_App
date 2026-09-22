class FoodItem {
  final String id;
  final String name;
  final int calories;
  final String category;
  final String serving;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    this.category = 'general',
    this.serving = '1 serving',
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? 'general',
        serving: json['serving']?.toString() ?? '1 serving',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'category': category,
        'serving': serving,
      };
}

class DailyNutritionSummary {
  final int consumedCalories;
  final int targetCalories;
  final String breakfastText;
  final int breakfastCalories;
  final String lunchText;
  final int lunchCalories;
  final String dinnerText;
  final int dinnerCalories;

  const DailyNutritionSummary({
    this.consumedCalories = 0,
    this.targetCalories = 2000,
    this.breakfastText = '',
    this.breakfastCalories = 0,
    this.lunchText = '',
    this.lunchCalories = 0,
    this.dinnerText = '',
    this.dinnerCalories = 0,
  });

  factory DailyNutritionSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailyNutritionSummary();
    return DailyNutritionSummary(
      consumedCalories: (json['consumedCalories'] as num?)?.toInt() ?? (json['totalCalories'] as num?)?.toInt() ?? 0,
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 2000,
      breakfastText: json['breakfastText'] as String? ?? '',
      breakfastCalories: (json['breakfastCalories'] as num?)?.toInt() ?? 0,
      lunchText: json['lunchText'] as String? ?? '',
      lunchCalories: (json['lunchCalories'] as num?)?.toInt() ?? 0,
      dinnerText: json['dinnerText'] as String? ?? '',
      dinnerCalories: (json['dinnerCalories'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'consumedCalories': consumedCalories,
        'targetCalories': targetCalories,
        'breakfastText': breakfastText,
        'breakfastCalories': breakfastCalories,
        'lunchText': lunchText,
        'lunchCalories': lunchCalories,
        'dinnerText': dinnerText,
        'dinnerCalories': dinnerCalories,
      };
}
