import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class SleepAnalysisResult {
  final double hours;
  final String bedTime;
  final String wakeTime;
  final int briefInterruptions;
  final String method;

  SleepAnalysisResult({
    required this.hours,
    required this.bedTime,
    required this.wakeTime,
    required this.briefInterruptions,
    required this.method,
  });
}

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<StepCount>? _stepCountSubscription;
  int _baselineSteps = -1;
  int _todaySteps = 0;
  String _lastStepDate = '';
  final ValueNotifier<int> stepsNotifier = ValueNotifier<int>(0);

  static const String _prefKeyLastDate = 'livefit_step_last_date';
  static const String _prefKeyBaseline = 'livefit_step_baseline';
  static const String _prefKeyTodaySteps = 'livefit_step_today_steps';

  // --- 1. PEDOMETER SENSOR WITH 0 / -1 CHECK & MIDNIGHT RESET ---
  Future<void> initPedometerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final savedDate = prefs.getString(_prefKeyLastDate) ?? '';

      if (savedDate == todayStr) {
        // Same day: restore today's steps and baseline
        _lastStepDate = todayStr;
        _baselineSteps = prefs.getInt(_prefKeyBaseline) ?? -1;
        _todaySteps = prefs.getInt(_prefKeyTodaySteps) ?? 0;
      } else {
        // New day started (after midnight 12:00): count starts from zero
        _lastStepDate = todayStr;
        _baselineSteps = -1;
        _todaySteps = 0;
        await prefs.setString(_prefKeyLastDate, todayStr);
        await prefs.setInt(_prefKeyTodaySteps, 0);
      }

      stepsNotifier.value = _todaySteps;
    } catch (e) {
      debugPrint('Error restoring pedometer state: $e');
    }
  }

  void startStepCounting({
    required Function(int todaySteps, int rawSensorCount) onStepUpdate,
  }) async {
    await initPedometerState();

    // Only attempt native pedometer hardware sensor on mobile devices
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (StepCount event) async {
            final rawCount = event.steps;

            // Condition 1: Check if step count is 0 or -1 (sensor initial/calibration state)
            if (rawCount <= 0 || rawCount == -1) {
              debugPrint('Pedometer sensor returned initial/idle value ($rawCount). Waiting for valid reading.');
              return;
            }

            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final prefs = await SharedPreferences.getInstance();

            // Condition 2: If date changed (crossing 12:00 midnight while app is active)
            if (_lastStepDate != todayStr) {
              _lastStepDate = todayStr;
              _baselineSteps = rawCount; // New day baseline starts at current hardware reading
              _todaySteps = 0;
              await prefs.setString(_prefKeyLastDate, todayStr);
              await prefs.setInt(_prefKeyBaseline, _baselineSteps);
              await prefs.setInt(_prefKeyTodaySteps, 0);
              stepsNotifier.value = 0;
              onStepUpdate(0, rawCount);
              return;
            }

            // Condition 3: Same day initialization
            if (_baselineSteps <= 0) {
              _baselineSteps = max(0, rawCount - _todaySteps);
              await prefs.setInt(_prefKeyBaseline, _baselineSteps);
            }

            // Condition 4: Device reboot detected (hardware counter reset lower than baseline)
            if (rawCount < _baselineSteps) {
              debugPrint('Device reboot detected. Re-calibrating baseline from $_baselineSteps to $rawCount.');
              _baselineSteps = max(0, rawCount - _todaySteps);
              await prefs.setInt(_prefKeyBaseline, _baselineSteps);
            }

            // Condition 5: Calculate today's steps by subtracting the baseline
            final calculatedSteps = rawCount - _baselineSteps;
            if (calculatedSteps > _todaySteps) {
              _todaySteps = calculatedSteps;
            }

            await prefs.setInt(_prefKeyTodaySteps, _todaySteps);
            stepsNotifier.value = _todaySteps;
            onStepUpdate(_todaySteps, rawCount);
          },
          onError: (error) {
            debugPrint('Pedometer sensor stream error: $error');
          },
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint('Pedometer stream initialization failed: $e');
      }
    }
  }

  void stopStepCounting() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }

  void addSimulatedSteps(int amount, Function(int todaySteps) onStepUpdate) async {
    _todaySteps += amount;
    stepsNotifier.value = _todaySteps;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyTodaySteps, _todaySteps);
    } catch (_) {}
    onStepUpdate(_todaySteps);
  }

  // --- 2. GEOLOCATION (Open-Meteo Weather) ---
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          return await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Geolocator position retrieval failed: $e');
    }

    // Dynamic Network IP location fallback if GPS sensor is off or denied
    try {
      final url = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=en');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 5000,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('IP location retrieval fallback failed: $e');
    }

    return null;
  }

  /// Reverse geocodes coordinates to a friendly city name
  Future<String?> getCityFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'] ?? data['locality'] ?? data['principalSubdivision'];
        if (city != null && city.toString().trim().isNotEmpty) {
          return city.toString().trim();
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode city retrieval failed: $e');
    }
    return null;
  }

  // --- 3. SLEEP TRACKING (usage_stats with 2-Minute Inactivity Threshold) ---
  /// Analyzes phone activity between 10 PM and 8 AM:
  /// - Phone usage < 2 min is treated as checking time/messages and NOT considered waking up.
  /// - Continuous usage in the morning indicates true wake-up time.
  Future<SleepAnalysisResult> estimateSleepFromDeviceUsage() async {
    final now = DateTime.now();
    final nightStart = DateTime(now.year, now.month, now.day - 1, 22, 0); // 10:00 PM yesterday
    DateTime morningEnd = DateTime(now.year, now.month, now.day, 8, 0);   // 08:00 AM today
    if (now.isBefore(morningEnd)) {
      morningEnd = now;
    }

    // Default fallback values
    final fallbackResult = SleepAnalysisResult(
      hours: 7.5,
      bedTime: '11:15 PM',
      wakeTime: '06:45 AM',
      briefInterruptions: 1,
      method: 'estimated',
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        bool? isPermissionGranted = await UsageStats.checkUsagePermission();
        if (isPermissionGranted == false) {
          await UsageStats.grantUsagePermission();
          return fallbackResult;
        }

        List<EventUsageInfo> events = await UsageStats.queryEvents(nightStart, morningEnd);
        if (events.isEmpty) {
          return fallbackResult;
        }

        // Parse and sort all events chronologically
        final validTimestamps = <int>[];
        for (var ev in events) {
          final ts = int.tryParse(ev.timeStamp ?? '');
          if (ts != null && ts > 0) {
            validTimestamps.add(ts);
          }
        }
        validTimestamps.sort();

        if (validTimestamps.isEmpty) {
          return fallbackResult;
        }

        // Group events into continuous phone usage clusters (< 60s apart)
        final usageSessions = <_PhoneSession>[];
        int sessionStart = validTimestamps.first;
        int sessionEnd = validTimestamps.first;

        for (int i = 1; i < validTimestamps.length; i++) {
          final current = validTimestamps[i];
          if (current - sessionEnd < 60 * 1000) {
            // Continuation of same usage session
            sessionEnd = current;
          } else {
            usageSessions.add(_PhoneSession(sessionStart, sessionEnd));
            sessionStart = current;
            sessionEnd = current;
          }
        }
        usageSessions.add(_PhoneSession(sessionStart, sessionEnd));

        // Threshold constant: 2 minutes (120,000 milliseconds)
        const int twoMinutesMs = 2 * 60 * 1000;
        int briefInterruptionsCount = 0;

        // 1. Determine Sleep Onset:
        // When user stops using the phone late at night (between 10 PM and 1:30 AM)
        int sleepOnsetTs = nightStart.millisecondsSinceEpoch + (60 * 60 * 1000); // Default 11:00 PM
        for (var session in usageSessions) {
          final sessionDate = DateTime.fromMillisecondsSinceEpoch(session.end);
          if (sessionDate.hour >= 22 || sessionDate.hour < 2) {
            if (session.durationMs >= twoMinutesMs) {
              sleepOnsetTs = session.end; // User was actively using phone
            }
          }
        }

        // 2. Determine Wake-Up Time:
        // In the morning (after 5:00 AM), check when user starts using phone continuously (>= 2 minutes)
        int wakeUpTs = morningEnd.millisecondsSinceEpoch;
        bool foundMorningContinuousWake = false;

        for (var session in usageSessions) {
          final sessionDate = DateTime.fromMillisecondsSinceEpoch(session.start);

          // If session is during middle of night (between 1:00 AM and 5:00 AM)
          if (sessionDate.hour >= 1 && sessionDate.hour < 5) {
            if (session.durationMs < twoMinutesMs) {
              // User checked time or quick call (< 2 min): DO NOT COUNT AS WAKE UP
              briefInterruptionsCount++;
            }
          }

          // If session is in morning window (after 5:00 AM)
          if (sessionDate.hour >= 5) {
            if (session.durationMs >= twoMinutesMs) {
              // User uses phone continuously for >= 2 minutes -> considered woken up
              wakeUpTs = session.start;
              foundMorningContinuousWake = true;
              break;
            } else {
              // Brief check in morning < 2 min
              briefInterruptionsCount++;
            }
          }
        }

        if (!foundMorningContinuousWake) {
          // If no >= 2 min session occurred yet, pick last recorded event or current time
          wakeUpTs = min(morningEnd.millisecondsSinceEpoch, validTimestamps.last);
        }

        // 3. Compute Sleep Time in Hours
        int netSleepMillis = wakeUpTs - sleepOnsetTs;
        if (netSleepMillis < 0) {
          netSleepMillis = (7.5 * 3600 * 1000).round();
        }

        double sleepHours = netSleepMillis / (1000.0 * 60.0 * 60.0);
        // Bound sleep to realistic physiological parameters (3.5 to 11.5 hours)
        sleepHours = sleepHours.clamp(3.5, 11.5);
        sleepHours = (sleepHours * 10).round() / 10.0;

        final bedTimeStr = DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(sleepOnsetTs));
        final wakeTimeStr = DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(wakeUpTs));

        return SleepAnalysisResult(
          hours: sleepHours,
          bedTime: bedTimeStr,
          wakeTime: wakeTimeStr,
          briefInterruptions: briefInterruptionsCount,
          method: 'usage_stats',
        );
      } catch (e) {
        debugPrint('Usage stats sleep calculation fallback: $e');
      }
    }

    return fallbackResult;
  }
}

class _PhoneSession {
  final int start;
  final int end;
  _PhoneSession(this.start, this.end);
  int get durationMs => max(0, end - start);
}
