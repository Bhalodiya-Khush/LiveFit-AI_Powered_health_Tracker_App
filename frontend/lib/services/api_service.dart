import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configured for wired USB debugging (via adb reverse tcp:5050 tcp:5050) & local development
  static String get defaultBaseUrl {
    // 127.0.0.1 routes seamlessly to host PC via adb reverse during wired debug,
    // and works out of the box for Chrome / Web debugging.
    return 'http://127.0.0.1:5050/api';
  }

  String _baseUrl = defaultBaseUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('livefit_base_url', url);
  }

  Future<void> resetBaseUrl() async {
    _baseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('livefit_base_url');
  }

  Future<bool> testConnection([String? customUrl]) async {
    final target = (customUrl ?? _baseUrl).trim();
    try {
      final root = target.endsWith('/api') ? target.substring(0, target.length - 4) : target;
      final res = await http.get(Uri.parse(root)).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('livefit_jwt_token');
    final savedUrl = prefs.getString('livefit_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      // Invalidate stale Wi-Fi IPs or emulator URLs so wired debug works seamlessly
      if (savedUrl.contains('172.21.33.224') ||
          savedUrl.contains('10.0.2.2') ||
          savedUrl.contains('10.174.140') ||
          (kIsWeb && !savedUrl.contains('127.0.0.1') && !savedUrl.contains('localhost'))) {
        _baseUrl = defaultBaseUrl;
        await prefs.setString('livefit_base_url', defaultBaseUrl);
      } else {
        _baseUrl = savedUrl;
      }
    } else {
      _baseUrl = defaultBaseUrl;
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('livefit_jwt_token', token);
    } else {
      await prefs.remove('livefit_jwt_token');
    }
  }

  Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) headers['Content-Type'] = 'application/json';
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String birthDate,
    String gender = 'male',
    double height = 175,
    double weight = 70,
    String healthHurdles = 'none',
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'birthDate': birthDate,
        'gender': gender,
        'height': height,
        'weight': weight,
        'healthHurdles': healthHurdles,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await setToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await setToken(data['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } on TimeoutException {
      throw Exception('Server connection timed out at $_baseUrl. Check your Wi-Fi connection.');
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      throw Exception('Cannot reach server at $_baseUrl. Check Wi-Fi.');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$_baseUrl/auth/profile');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['user'];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final url = Uri.parse('$_baseUrl/auth/profile');
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(updates),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['user'];
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> logout() async {
    await setToken(null);
  }

  // --- DAILY STATS & SENSORS ---
  Future<Map<String, dynamic>> getTodayStats() async {
    final url = Uri.parse('$_baseUrl/stats/today');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['stats'];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch today stats');
    }
  }

  Future<void> logSteps(int steps, {int? rawSensorSteps}) async {
    final url = Uri.parse('$_baseUrl/stats/steps');
    final payload = <String, dynamic>{'steps': steps};
    if (rawSensorSteps != null && rawSensorSteps > 0) {
      payload['rawSensorSteps'] = rawSensorSteps;
    }
    await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
  }

  Future<void> logSleep(
    double sleepHours, {
    String? bedTime,
    String? wakeTime,
    int? briefInterruptions,
    String? method,
  }) async {
    final url = Uri.parse('$_baseUrl/stats/sleep');
    final payload = <String, dynamic>{'sleepHours': sleepHours};
    if (bedTime != null) payload['sleepBedTime'] = bedTime;
    if (wakeTime != null) payload['sleepWakeTime'] = wakeTime;
    if (briefInterruptions != null) payload['sleepInterruptions'] = briefInterruptions;
    if (method != null) payload['method'] = method;

    await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
  }

  // --- MEALS & NUTRITION ---
  Future<Map<String, dynamic>> analyzeMeal({
    String? imageBase64,
    required String mealType,
  }) async {
    final url = Uri.parse('$_baseUrl/meals/analyze');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'imageBase64': imageBase64 ?? '',
        'mealType': mealType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Meal analysis failed');
    }
  }

  Future<Map<String, dynamic>> getTodayMeals() async {
    final url = Uri.parse('$_baseUrl/meals/today');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch meals');
    }
  }

  // --- EXERCISES & COMPENDIUM ---
  Future<Map<String, dynamic>> getSuggestedExercises({
    double lat = 22.6916,
    double lon = 72.8634,
  }) async {
    final url = Uri.parse('$_baseUrl/exercises/suggested');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'lat': lat, 'lon': lon}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch exercises');
    }
  }

  Future<Map<String, dynamic>> markExerciseDone(String id) async {
    final url = Uri.parse('$_baseUrl/exercises/mark-done/$id');
    final response = await http.post(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark exercise done');
    }
  }

  Future<Map<String, dynamic>> getTodayExercises() async {
    final url = Uri.parse('$_baseUrl/exercises/today');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch today exercises');
    }
  }

  // --- AI HEALTH CHAT ---
  Future<String> sendChatMessage(String message, {double? lat, double? lon}) async {
    final url = Uri.parse('$_baseUrl/chat/message');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'message': message,
        'lat': lat ?? 22.6916,
        'lon': lon ?? 72.8634,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['response'];
    } else {
      throw Exception(data['message'] ?? 'AI chat failed');
    }
  }

  Future<List<dynamic>> getChatHistory() async {
    final url = Uri.parse('$_baseUrl/chat/history');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['history'] ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch chat history');
    }
  }

  // --- WEEKLY REPORT ---
  Future<Map<String, dynamic>> getWeeklyReport() async {
    final url = Uri.parse('$_baseUrl/reports/weekly');
    final response = await http.get(url, headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch weekly report');
    }
  }
}
