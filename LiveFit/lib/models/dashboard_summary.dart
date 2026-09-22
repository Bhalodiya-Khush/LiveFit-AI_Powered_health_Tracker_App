import 'user_model.dart';
import 'food_item.dart';

class DashboardSummary {
  final String date;
  final UserModel user;
  final int steps;
  final int stepGoal;
  final String stepSource;
  final int sleepMinutes;
  final int sleepGoalMinutes;
  final String sleepTime;
  final String wakeUpTime;
  final String sleepSource;
  final DailyNutritionSummary nutrition;
  final int burnedCalories;
  final int? healthScore;

  const DashboardSummary({
    required this.date,
    required this.user,
    required this.steps,
    required this.stepGoal,
    required this.stepSource,
    required this.sleepMinutes,
    required this.sleepGoalMinutes,
    required this.sleepTime,
    required this.wakeUpTime,
    required this.sleepSource,
    required this.nutrition,
    required this.burnedCalories,
    this.healthScore,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final stepsJson = json['steps'] as Map<String, dynamic>? ?? {};
    final sleepJson = json['sleep'] as Map<String, dynamic>? ?? {};
    final nutritionJson = json['nutrition'] as Map<String, dynamic>? ?? {};

    return DashboardSummary(
      date: json['date'] as String? ?? '',
      user: UserModel.fromJson(userJson),
      steps: (stepsJson['count'] as num?)?.toInt() ?? 0,
      stepGoal: (stepsJson['goal'] as num?)?.toInt() ?? 10000,
      stepSource: stepsJson['source'] as String? ?? 'sensor',
      sleepMinutes: (sleepJson['minutes'] as num?)?.toInt() ?? 0,
      sleepGoalMinutes: (sleepJson['goalMinutes'] as num?)?.toInt() ?? 480,
      sleepTime: sleepJson['sleepTime'] as String? ?? '23:30',
      wakeUpTime: sleepJson['wakeUpTime'] as String? ?? '07:00',
      sleepSource: sleepJson['source'] as String? ?? 'auto',
      nutrition: DailyNutritionSummary.fromJson(nutritionJson),
      burnedCalories: (json['burnedCalories'] as num?)?.toInt() ?? 0,
      healthScore: (json['healthScore'] as num?)?.toInt(),
    );
  }
}
