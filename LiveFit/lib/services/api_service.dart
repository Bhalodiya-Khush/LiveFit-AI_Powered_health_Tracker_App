import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/dashboard_summary.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AuthService _auth = AuthService();

  String get baseUrl => _auth.baseUrl;

  bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _headers({bool requiresAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };
    if (requiresAuth && _auth.token != null) {
      map['Authorization'] = 'Bearer ${_auth.token}';
    }
    return map;
  }

  /// Fetch combined live dashboard from MongoDB for today
  Future<DashboardSummary?> fetchTodayDashboard() async {
    if (_isTestEnvironment) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard/today'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DashboardSummary.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sync steps count to MongoDB
  Future<bool> syncSteps({required int steps, String source = 'sensor'}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/steps/sync'),
            headers: _headers(),
            body: jsonEncode({
              'steps': steps,
              'source': source,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sync sleep session to MongoDB
  Future<bool> syncSleep({
    required int sleepMinutes,
    required int sleepGoalMinutes,
    required String sleepTime,
    required String wakeUpTime,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sleep/sync'),
            headers: _headers(),
            body: jsonEncode({
              'sleepMinutes': sleepMinutes,
              'sleepGoalMinutes': sleepGoalMinutes,
              'sleepTime': sleepTime,
              'wakeUpTime': wakeUpTime,
              'source': 'auto',
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Save daily meal nutrition to MongoDB
  Future<bool> saveNutrition({
    required String breakfastText,
    required int breakfastCalories,
    required String lunchText,
    required int lunchCalories,
    required String dinnerText,
    required int dinnerCalories,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/nutrition/log'),
            headers: _headers(),
            body: jsonEncode({
              'breakfastText': breakfastText,
              'breakfastCalories': breakfastCalories,
              'lunchText': lunchText,
              'lunchCalories': lunchCalories,
              'dinnerText': dinnerText,
              'dinnerCalories': dinnerCalories,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Calculate calories for meal text query using MongoDB food database
  Future<int> calculateMealCalories(String query) async {
    if (query.trim().isEmpty) return 0;
    if (_isTestEnvironment) return _localFallbackCalculate(query);
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/food/calculate'),
            headers: _headers(requiresAuth: false),
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['totalCalories'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return _localFallbackCalculate(query);
  }

  /// Record completed activity/workout to MongoDB
  Future<bool> logActivity({
    required String activityType,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/activities/log'),
            headers: _headers(),
            body: jsonEncode({
              'activityType': activityType,
              'durationMinutes': durationMinutes,
              'caloriesBurned': caloriesBurned,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Save synthesized daily health score to MongoDB
  Future<bool> saveHealthScore(int score, {String breakdown = ''}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/health-score/save'),
            headers: _headers(),
            body: jsonEncode({
              'score': score,
              'breakdown': breakdown,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Update user profile & daily goals in MongoDB
  Future<UserModel?> updateProfile({
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    UserGoals? goals,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (weight != null) body['weight'] = weight;
      if (height != null) body['height'] = height;
      if (goals != null) body['goals'] = goals.toJson();

      final response = await http
          .put(
            Uri.parse('$baseUrl/user/profile'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final updated = UserModel.fromJson(data['user']);
          await _auth.updateCachedUser(updated);
          return updated;
        }
      }
    } catch (_) {}
    return null;
  }

  int _localFallbackCalculate(String input) {
    // Quick offline fallback
    if (input.trim().isEmpty) return 0;
    const fallback = {
      'roti': 100,
      'chapati': 100,
      'dal': 150,
      'rice': 200,
      'egg': 70,
      'eggs': 140,
      'oats': 150,
      'tea': 40,
      'salad': 60,
      'khichdi': 220,
      'curd': 90,
      'paneer': 260,
      'chicken': 240,
    };
    int total = 0;
    for (var item in input.split(RegExp(r'[,+]'))) {
      final clean = item.trim().toLowerCase();
      if (clean.isEmpty) continue;
      final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(clean);
      int qty = 1;
      String name = clean;
      if (match != null) {
        qty = int.tryParse(match.group(1) ?? '1') ?? 1;
        name = match.group(2)?.trim() ?? clean;
      }
      int cal = fallback[name] ?? 120;
      total += (cal * qty);
    }
    return total;
  }
}
