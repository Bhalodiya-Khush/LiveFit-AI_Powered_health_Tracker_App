import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepSensorService {
  static const String _prefKeyBaseline = 'livefit_pedometer_baseline';
  static const String _prefKeyDate = 'livefit_pedometer_date';
  static const String _prefKeyTodaySteps = 'livefit_today_steps';

  static final StepSensorService _instance = StepSensorService._internal();
  factory StepSensorService() => _instance;
  StepSensorService._internal();

  final StreamController<int> _stepStreamController = StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepStreamController.stream;

  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  bool _isSensorAvailable = false;
  bool _isSensorActive = false;
  int _currentDailySteps = 0;
  String _pedestrianStatus = 'Unknown';

  bool get isSensorAvailable => _isSensorAvailable;
  bool get isSensorActive => _isSensorActive;
  int get currentDailySteps => _currentDailySteps;
  String get pedestrianStatus => _pedestrianStatus;

  /// Initialize step counting from hardware sensor or stored daily cache
  Future<int> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastSavedDate = prefs.getString(_prefKeyDate) ?? '';

    if (lastSavedDate == today) {
      _currentDailySteps = prefs.getInt(_prefKeyTodaySteps) ?? 0;
    } else {
      // New day: reset daily steps
      _currentDailySteps = 0;
      await prefs.setString(_prefKeyDate, today);
      await prefs.setInt(_prefKeyTodaySteps, 0);
      await prefs.remove(_prefKeyBaseline);
    }

    // Only mobile platforms (Android/iOS) have physical pedometer sensors
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _startHardwareSensor();
    } else {
      _isSensorAvailable = false;
      _isSensorActive = false;
    }

    return _currentDailySteps;
  }

  Future<void> _startHardwareSensor() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          _isSensorAvailable = false;
          return;
        }
      }

      _isSensorAvailable = true;

      // Listen to hardware step count stream
      _pedometerSubscription?.cancel();
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        _onStepCountReceived,
        onError: (error) {
          _isSensorActive = false;
          _isSensorAvailable = false;
        },
        cancelOnError: false,
      );

      // Listen to walking / stopped status
      _statusSubscription?.cancel();
      _statusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus status) {
          _pedestrianStatus = status.status;
        },
        onError: (_) {},
        cancelOnError: false,
      );

      _isSensorActive = true;
    } catch (e) {
      _isSensorAvailable = false;
      _isSensorActive = false;
    }
  }

  Future<void> _onStepCountReceived(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastSavedDate = prefs.getString(_prefKeyDate) ?? '';

    // If day rolled over
    if (lastSavedDate != today) {
      await prefs.setString(_prefKeyDate, today);
      await prefs.setInt(_prefKeyBaseline, event.steps);
      _currentDailySteps = 0;
      await prefs.setInt(_prefKeyTodaySteps, 0);
      _stepStreamController.add(_currentDailySteps);
      return;
    }

    int? baseline = prefs.getInt(_prefKeyBaseline);
    if (baseline == null || baseline > event.steps) {
      // First event of the day or phone restarted
      baseline = event.steps;
      await prefs.setInt(_prefKeyBaseline, baseline);
    }

    final calculatedSteps = (event.steps - baseline).clamp(0, 100000);
    if (calculatedSteps > _currentDailySteps) {
      _currentDailySteps = calculatedSteps;
      await prefs.setInt(_prefKeyTodaySteps, _currentDailySteps);
      _stepStreamController.add(_currentDailySteps);
    }
  }

  /// Manually adjust steps (e.g., from StepTrackingScreen or calibration)
  Future<void> setStepsManually(int steps) async {
    _currentDailySteps = steps.clamp(0, 100000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDate, _getTodayDateString());
    await prefs.setInt(_prefKeyTodaySteps, _currentDailySteps);
    _stepStreamController.add(_currentDailySteps);
  }

  /// Sync steps to backend API
  Future<bool> syncStepsToBackend({
    required String baseUrl,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/steps/sync');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'steps': _currentDailySteps,
              'source': _isSensorActive ? 'sensor' : 'manual',
              'date': _getTodayDateString(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _pedometerSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepStreamController.close();
  }
}
