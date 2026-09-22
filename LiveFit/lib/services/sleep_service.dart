import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SleepRecord {
  final String date;
  final int sleepMinutes;
  final int sleepGoalMinutes;
  final String sleepTime;
  final String wakeUpTime;
  final String source;

  SleepRecord({
    required this.date,
    required this.sleepMinutes,
    required this.sleepGoalMinutes,
    required this.sleepTime,
    required this.wakeUpTime,
    this.source = 'auto',
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'sleepMinutes': sleepMinutes,
        'sleepGoalMinutes': sleepGoalMinutes,
        'sleepTime': sleepTime,
        'wakeUpTime': wakeUpTime,
        'source': source,
      };

  factory SleepRecord.fromJson(Map<String, dynamic> json) => SleepRecord(
        date: json['date'] as String? ?? '',
        sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
        sleepGoalMinutes: (json['sleepGoalMinutes'] as num?)?.toInt() ?? 480,
        sleepTime: json['sleepTime'] as String? ?? '00:00',
        wakeUpTime: json['wakeUpTime'] as String? ?? '00:00',
        source: json['source'] as String? ?? 'auto',
      );
}

class SleepService {
  static const String _prefKeyIsSleeping = 'livefit_is_sleeping';
  static const String _prefKeyStartTime = 'livefit_sleep_start_time';
  static const String _prefKeyLastMinutes = 'livefit_last_sleep_minutes';
  static const String _prefKeyLastSleepTime = 'livefit_last_sleep_time';
  static const String _prefKeyLastWakeTime = 'livefit_last_wake_time';
  static const String _prefKeySleepGoal = 'livefit_sleep_goal_minutes';
  static const String _prefKeyHistory = 'livefit_sleep_history';

  static final SleepService _instance = SleepService._internal();
  factory SleepService() => _instance;
  SleepService._internal();

  bool _isSleeping = false;
  DateTime? _sleepStartTime;
  int _sleepMinutes = 0;
  int _sleepGoalMinutes = 480; // 8 hours
  String _sleepTime = '00:00';
  String _wakeUpTime = '00:00';
  List<SleepRecord> _history = [];

  bool get isSleeping => _isSleeping;
  DateTime? get sleepStartTime => _sleepStartTime;
  int get sleepMinutes => _sleepMinutes;
  int get sleepGoalMinutes => _sleepGoalMinutes;
  String get sleepTime => _sleepTime;
  String get wakeUpTime => _wakeUpTime;
  List<SleepRecord> get history => List.unmodifiable(_history);

  /// Load persisted sleep state, active session, and history from local storage
  Future<void> initialize({int? defaultGoalMinutes}) async {
    final prefs = await SharedPreferences.getInstance();

    _sleepGoalMinutes = defaultGoalMinutes ?? prefs.getInt(_prefKeySleepGoal) ?? 480;
    _isSleeping = prefs.getBool(_prefKeyIsSleeping) ?? false;

    final startIso = prefs.getString(_prefKeyStartTime);
    if (startIso != null && startIso.isNotEmpty) {
      _sleepStartTime = DateTime.tryParse(startIso);
      // If sleeping for more than 18 hours, assume session expired
      if (_sleepStartTime != null &&
          DateTime.now().difference(_sleepStartTime!).inHours > 18) {
        _isSleeping = false;
        _sleepStartTime = null;
        await prefs.setBool(_prefKeyIsSleeping, false);
        await prefs.remove(_prefKeyStartTime);
      }
    }

    _sleepMinutes = prefs.getInt(_prefKeyLastMinutes) ?? 0;
    _sleepTime = prefs.getString(_prefKeyLastSleepTime) ?? '23:00';
    _wakeUpTime = prefs.getString(_prefKeyLastWakeTime) ?? '07:00';

    // If no sleep recorded yet, set a sensible default for demo
    if (_sleepMinutes == 0 && !_isSleeping) {
      _sleepMinutes = 450; // 7h 30m
      _sleepTime = '23:30';
      _wakeUpTime = '07:00';
    }

    _loadHistoryFromPrefs(prefs);
  }

  /// Start Sleep Session (User taps "Start Sleep")
  Future<void> startSleep() async {
    _isSleeping = true;
    _sleepStartTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsSleeping, true);
    await prefs.setString(_prefKeyStartTime, _sleepStartTime!.toIso8601String());
  }

  /// Wake Up / Stop Sleep Session (User taps "Wake Up")
  Future<SleepRecord> wakeUp({String? baseUrl, String? token}) async {
    final now = DateTime.now();
    final start = _sleepStartTime ?? now.subtract(const Duration(hours: 7));

    final durationMinutes = now.difference(start).inMinutes.clamp(10, 1440);

    _sleepMinutes = durationMinutes;
    _sleepTime = _formatTime(start);
    _wakeUpTime = _formatTime(now);
    _isSleeping = false;
    _sleepStartTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsSleeping, false);
    await prefs.remove(_prefKeyStartTime);
    await prefs.setInt(_prefKeyLastMinutes, _sleepMinutes);
    await prefs.setString(_prefKeyLastSleepTime, _sleepTime);
    await prefs.setString(_prefKeyLastWakeTime, _wakeUpTime);

    final record = SleepRecord(
      date: _getTodayDateString(),
      sleepMinutes: _sleepMinutes,
      sleepGoalMinutes: _sleepGoalMinutes,
      sleepTime: _sleepTime,
      wakeUpTime: _wakeUpTime,
      source: 'auto',
    );

    _addRecordToHistory(record, prefs);

    // Sync to backend if configured
    if (baseUrl != null && baseUrl.isNotEmpty) {
      unawaited(syncSleepToBackend(baseUrl: baseUrl, token: token));
    }

    return record;
  }

  /// Log or adjust sleep manually with custom duration & times
  Future<void> logSleepManually({
    required int minutes,
    required String sleepTime,
    required String wakeUpTime,
    String? baseUrl,
    String? token,
  }) async {
    _sleepMinutes = minutes.clamp(0, 1440);
    _sleepTime = sleepTime;
    _wakeUpTime = wakeUpTime;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyLastMinutes, _sleepMinutes);
    await prefs.setString(_prefKeyLastSleepTime, _sleepTime);
    await prefs.setString(_prefKeyLastWakeTime, _wakeUpTime);

    final record = SleepRecord(
      date: _getTodayDateString(),
      sleepMinutes: _sleepMinutes,
      sleepGoalMinutes: _sleepGoalMinutes,
      sleepTime: _sleepTime,
      wakeUpTime: _wakeUpTime,
      source: 'manual',
    );

    _addRecordToHistory(record, prefs);

    if (baseUrl != null && baseUrl.isNotEmpty) {
      unawaited(syncSleepToBackend(baseUrl: baseUrl, token: token));
    }
  }

  Future<void> updateSleepGoal(int goalMinutes) async {
    _sleepGoalMinutes = goalMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeySleepGoal, _sleepGoalMinutes);
  }

  /// Calculate live elapsed sleep minutes while asleep
  int getElapsedSleepMinutes() {
    if (!_isSleeping || _sleepStartTime == null) return 0;
    return DateTime.now().difference(_sleepStartTime!).inMinutes;
  }

  /// Sync sleep data to backend API
  Future<bool> syncSleepToBackend({
    required String baseUrl,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/sleep/sync');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'sleepMinutes': _sleepMinutes,
              'sleepGoalMinutes': _sleepGoalMinutes,
              'sleepTime': _sleepTime,
              'wakeUpTime': _wakeUpTime,
              'source': 'auto',
              'date': _getTodayDateString(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _loadHistoryFromPrefs(SharedPreferences prefs) {
    final rawJson = prefs.getString(_prefKeyHistory);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(rawJson);
        _history = list.map((e) => SleepRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _generateDefaultHistory();
      }
    } else {
      _generateDefaultHistory();
    }
  }

  void _generateDefaultHistory() {
    final now = DateTime.now();
    _history = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      // 6h 30m to 8h 15m variance
      final minutes = 400 + (index * 15 % 80);
      return SleepRecord(
        date: dateStr,
        sleepMinutes: minutes,
        sleepGoalMinutes: 480,
        sleepTime: '23:30',
        wakeUpTime: '07:15',
        source: 'auto',
      );
    });
  }

  void _addRecordToHistory(SleepRecord record, SharedPreferences prefs) {
    _history.removeWhere((item) => item.date == record.date);
    _history.add(record);
    if (_history.length > 14) {
      _history = _history.sublist(_history.length - 14);
    }
    prefs.setString(_prefKeyHistory, jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
