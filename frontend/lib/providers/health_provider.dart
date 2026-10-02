import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/sensor_service.dart';

class HealthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SensorService _sensors = SensorService();

  // Daily Dashboard Stats
  int _steps = 0;
  int _rawSensorCount = 0;
  double _sleepHours = 0.0;
  String _sleepBedTime = '';
  String _sleepWakeTime = '';
  int _sleepInterruptions = 0;
  int _caloriesConsumed = 0;
  int _caloriesBurned = 0;
  bool _isLoadingDashboard = false;

  // Weather & Location
  Map<String, dynamic>? _weather;
  double _latitude = 22.6916;
  double _longitude = 72.8634;

  // Exercises
  List<dynamic> _suggestedExercises = [];
  bool _isLoadingExercises = false;

  // Meals
  List<dynamic> _todayMeals = [];
  Map<String, dynamic> _mealTotals = {};
  bool _isLoadingMeals = false;
  String _currentMealType = 'lunch';

  // AI Chat
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isSendingChat = false;

  // Weekly Report
  Map<String, dynamic>? _weeklyReport;
  bool _isLoadingReport = false;

  // Getters
  int get steps => _steps;
  int get rawSensorCount => _rawSensorCount;
  double get sleepHours => _sleepHours;
  String get sleepBedTime => _sleepBedTime;
  String get sleepWakeTime => _sleepWakeTime;
  int get sleepInterruptions => _sleepInterruptions;
  int get caloriesConsumed => _caloriesConsumed;
  int get caloriesBurned => _caloriesBurned;
  bool get isLoadingDashboard => _isLoadingDashboard;

  Map<String, dynamic>? get weather => _weather;
  List<dynamic> get suggestedExercises => _suggestedExercises;
  bool get isLoadingExercises => _isLoadingExercises;

  List<dynamic> get todayMeals => _todayMeals;
  Map<String, dynamic> get mealTotals => _mealTotals;
  bool get isLoadingMeals => _isLoadingMeals;
  String get currentMealType => _currentMealType;

  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  bool get isSendingChat => _isSendingChat;

  Map<String, dynamic>? get weeklyReport => _weeklyReport;
  bool get isLoadingReport => _isLoadingReport;

  Timer? _stepSyncTimer;

  void resetUserData() {
    _stepSyncTimer?.cancel();
    _sensors.stopStepCounting();
    _steps = 0;
    _rawSensorCount = 0;
    _sleepHours = 0.0;
    _sleepBedTime = '';
    _sleepWakeTime = '';
    _sleepInterruptions = 0;
    _caloriesConsumed = 0;
    _caloriesBurned = 0;
    _suggestedExercises = [];
    _todayMeals = [];
    _mealTotals = {};
    _currentMealType = 'lunch';
    _chatMessages = [];
    _weeklyReport = null;
    notifyListeners();
  }

  List<dynamic> _deduplicateExercises(List<dynamic> list) {
    final seen = <String>{};
    final unique = <dynamic>[];
    for (final item in list) {
      final name = (item['exerciseName'] ?? '').toString().trim().toLowerCase();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        unique.add(item);
      }
    }
    return unique.take(5).toList();
  }

  // --- 1. INITIALIZE DASHBOARD & SENSORS ---
  Future<void> initDashboard() async {
    resetUserData();
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      // 1. Fetch Today's stats from backend
      final stats = await _api.getTodayStats();
      _steps = stats['steps'] ?? 0;
      _sleepHours = (stats['sleepHours'] as num?)?.toDouble() ?? 0.0;
      _sleepBedTime = stats['sleepBedTime'] ?? '';
      _sleepWakeTime = stats['sleepWakeTime'] ?? '';
      _sleepInterruptions = stats['sleepInterruptions'] ?? 0;
      _caloriesConsumed = stats['caloriesConsumed'] ?? 0;
      _caloriesBurned = stats['caloriesBurned'] ?? 0;

      // 2. Fetch Location, Weather & Suggested Exercises
      await refreshWeatherAndLocation();

      // 3. Initialize Sensor listeners
      _initPedometerAndSleep();

      // 4. Fetch Meals & Chat History for this user
      await fetchTodayMeals();
      await loadChatHistory();
    } catch (e) {
      debugPrint('Dashboard init error: $e');
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  void _initPedometerAndSleep() {
    // Start pedometer sensor stream with initial value handling & baseline subtraction
    _sensors.startStepCounting(
      onStepUpdate: (todaySteps, rawSensorCount) {
        _rawSensorCount = rawSensorCount;
        if (todaySteps > _steps) {
          _steps = todaySteps;
          notifyListeners();
          _scheduleStepSync();
        }
      },
    );

    // If sleepHours is 0, estimate from device activity (usage_stats with 2-min threshold)
    if (_sleepHours == 0.0) {
      _sensors.estimateSleepFromDeviceUsage().then((result) {
        if (result.hours > 0) {
          _sleepHours = result.hours;
          _sleepBedTime = result.bedTime;
          _sleepWakeTime = result.wakeTime;
          _sleepInterruptions = result.briefInterruptions;
          notifyListeners();
          _api.logSleep(
            _sleepHours,
            bedTime: _sleepBedTime,
            wakeTime: _sleepWakeTime,
            briefInterruptions: _sleepInterruptions,
            method: result.method,
          );
        }
      });
    }
  }

  void addSimulatedSteps(int amount) {
    _sensors.addSimulatedSteps(amount, (updated) {
      _steps = updated;
      notifyListeners();
      _scheduleStepSync();
    });
  }

  void _scheduleStepSync() {
    _stepSyncTimer?.cancel();
    _stepSyncTimer = Timer(const Duration(seconds: 3), () {
      _api.logSteps(_steps, rawSensorSteps: _rawSensorCount);
    });
  }

  Future<void> updateSleep(double hours) async {
    _sleepHours = hours;
    notifyListeners();
    await _api.logSleep(
      hours,
      bedTime: _sleepBedTime,
      wakeTime: _sleepWakeTime,
      briefInterruptions: _sleepInterruptions,
      method: 'manual',
    );
  }

  // --- 2. WEATHER & LOCATION ---
  Future<void> refreshWeatherAndLocation() async {
    final pos = await _sensors.getCurrentLocation();
    if (pos != null) {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    }

    try {
      final res = await _api.getSuggestedExercises(lat: _latitude, lon: _longitude);
      _weather = res['weather'];
      if (res['exercises'] != null) {
        _suggestedExercises = _deduplicateExercises(res['exercises']);
      }
      if (_weather != null && (_weather!['city'] == null || _weather!['city'] == 'Current Location')) {
        final localCity = await _sensors.getCityFromCoordinates(_latitude, _longitude);
        if (localCity != null) {
          _weather!['city'] = localCity;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Weather refresh error: $e');
    }
  }

  // --- 3. EXERCISES & MET CALORIE BURNING ---
  Future<void> fetchExercises() async {
    _isLoadingExercises = true;
    notifyListeners();

    try {
      final res = await _api.getSuggestedExercises(lat: _latitude, lon: _longitude);
      _suggestedExercises = _deduplicateExercises(res['exercises'] ?? []);
      _weather = res['weather'];
      if (_weather != null && (_weather!['city'] == null || _weather!['city'] == 'Current Location')) {
        final localCity = await _sensors.getCityFromCoordinates(_latitude, _longitude);
        if (localCity != null) {
          _weather!['city'] = localCity;
        }
      }
    } catch (e) {
      debugPrint('Fetch exercises error: $e');
    } finally {
      _isLoadingExercises = false;
      notifyListeners();
    }
  }

  Future<int?> completeExercise(String id) async {
    try {
      final res = await _api.markExerciseDone(id);
      final burned = res['caloriesBurned'] as int?;
      
      // Update local state
      final index = _suggestedExercises.indexWhere((e) => e['_id'] == id);
      if (index != -1) {
        _suggestedExercises[index]['completed'] = true;
        _suggestedExercises[index]['caloriesBurned'] = burned;
      }
      _caloriesBurned = res['totalBurnedToday'] ?? (_caloriesBurned + (burned ?? 0));
      notifyListeners();
      return burned;
    } catch (e) {
      debugPrint('Complete exercise error: $e');
      return null;
    }
  }

  // --- 4. MEALS & GEMINI VISION ANALYSIS ---
  Future<void> fetchTodayMeals() async {
    _isLoadingMeals = true;
    notifyListeners();

    try {
      final res = await _api.getTodayMeals();
      _todayMeals = res['meals'] ?? [];
      _mealTotals = res['totals'] ?? {};
      _caloriesConsumed = _mealTotals['calories'] ?? _caloriesConsumed;
      if (res['currentMealType'] != null && res['currentMealType'].toString().isNotEmpty) {
        _currentMealType = res['currentMealType'].toString().toLowerCase();
      }
    } catch (e) {
      debugPrint('Fetch meals error: $e');
    } finally {
      _isLoadingMeals = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> logMealPhoto({
    String? base64Image,
    required String mealType,
  }) async {
    _isLoadingMeals = true;
    notifyListeners();

    try {
      final res = await _api.analyzeMeal(
        imageBase64: base64Image,
        mealType: mealType,
      );

      _caloriesConsumed = res['todayCaloriesConsumed'] ?? _caloriesConsumed;
      await fetchTodayMeals();
      return res;
    } catch (e) {
      debugPrint('Log meal error: $e');
      rethrow;
    } finally {
      _isLoadingMeals = false;
      notifyListeners();
    }
  }

  // --- 5. AI HEALTH CHAT WITH GEMINI ---
  Future<void> loadChatHistory() async {
    try {
      final history = await _api.getChatHistory();
      _chatMessages = List<Map<String, dynamic>>.from(history);
      notifyListeners();
    } catch (e) {
      debugPrint('Chat history load error: $e');
    }
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message immediately
    _chatMessages.add({
      'role': 'user',
      'message': message.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    _isSendingChat = true;
    notifyListeners();

    try {
      final aiAnswer = await _api.sendChatMessage(
        message.trim(),
        lat: _latitude,
        lon: _longitude,
      );

      _chatMessages.add({
        'role': 'model',
        'message': aiAnswer,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _chatMessages.add({
        'role': 'model',
        'message': 'Sorry, I had trouble answering right now. Please try again!',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      _isSendingChat = false;
      notifyListeners();
    }
  }

  // --- 6. WEEKLY REPORT ---
  Future<void> fetchWeeklyReport() async {
    _isLoadingReport = true;
    notifyListeners();

    try {
      _weeklyReport = await _api.getWeeklyReport();
    } catch (e) {
      debugPrint('Weekly report error: $e');
    } finally {
      _isLoadingReport = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stepSyncTimer?.cancel();
    _sensors.stopStepCounting();
    super.dispose();
  }
}
