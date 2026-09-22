import 'package:flutter/material.dart';

class WorkoutItem {
  final String title;
  final String duration;
  final int calories;
  final String reason;
  final IconData icon;

  const WorkoutItem({
    required this.title,
    required this.duration,
    required this.calories,
    required this.reason,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'duration': duration,
        'calories': calories,
        'reason': reason,
      };

  factory WorkoutItem.fromJson(Map<String, dynamic> json) => WorkoutItem(
        title: json['title'] as String? ?? 'Workout',
        duration: json['duration'] as String? ?? '15 mins',
        calories: (json['calories'] as num?)?.toInt() ?? 100,
        reason: json['reason'] as String? ?? '',
        icon: Icons.fitness_center_rounded,
      );
}

class WorkoutEngine {
  static List<WorkoutItem> generateRecommendations({
    required int age,
    required double weightKg,
    required String weatherCondition,
    required double tempC,
  }) {
    final isIndoor = tempC > 34 ||
        tempC < 12 ||
        ['Rain', 'Snow', 'Thunderstorm', 'Drizzle'].contains(weatherCondition);

    if (isIndoor) {
      return [
        WorkoutItem(
          title: 'Indoor High Knees & Cardio',
          duration: '15 mins',
          calories: (weightKg * 1.8).round(),
          reason: 'Recommended indoors due to $weatherCondition ($tempC°C). Safe cardio for age $age.',
          icon: Icons.flash_on_rounded,
        ),
        WorkoutItem(
          title: 'Bodyweight Squats & Core Planks',
          duration: '20 mins',
          calories: (weightKg * 2.0).round(),
          reason: 'Joint-friendly strength circuit tailored for your ${weightKg.toInt()} kg body weight.',
          icon: Icons.fitness_center_rounded,
        ),
        WorkoutItem(
          title: 'Yoga & Muscle Stretching',
          duration: '15 mins',
          calories: (weightKg * 1.1).round(),
          reason: 'Relieves stress and improves flexibility.',
          icon: Icons.self_improvement_rounded,
        ),
      ];
    } else {
      return [
        WorkoutItem(
          title: 'Outdoor Brisk Walking / Jogging',
          duration: '25 mins',
          calories: (weightKg * 2.5).round(),
          reason: 'Weather is pleasant ($tempC°C, $weatherCondition). Great outdoor oxygenation for age $age.',
          icon: Icons.directions_run_rounded,
        ),
        WorkoutItem(
          title: 'Cycling / Stair Climbing',
          duration: '20 mins',
          calories: (weightKg * 2.2).round(),
          reason: 'Burns excess calories and builds leg stamina for ${weightKg.toInt()} kg profile.',
          icon: Icons.directions_bike_rounded,
        ),
        WorkoutItem(
          title: 'Full Body Push-ups & Lunges',
          duration: '15 mins',
          calories: (weightKg * 1.8).round(),
          reason: 'Maintains lean muscular tone and boosts active metabolic rate.',
          icon: Icons.sports_gymnastics_rounded,
        ),
      ];
    }
  }
}
