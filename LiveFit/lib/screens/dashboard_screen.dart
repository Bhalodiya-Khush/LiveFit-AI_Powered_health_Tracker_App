import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/workout_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/sleep_service.dart';
import '../services/step_sensor_service.dart';
import '../services/weather_service.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final dynamic user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Services
  late GeminiService _geminiService;
  late WeatherService _weatherService;
  late StepSensorService _stepSensorService;
  late SleepService _sleepService;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<bool>? _sleepSubscription;

  // Active User Info
  late String _userName;
  late String _userEmail;
  late int _age;
  late double _weightKg;
  late double _heightCm;

  // Health Stats & State
  int _steps = 0;
  int _stepGoal = 10000;
  int _sleepMinutes = 450; // 7h 30m default
  int _sleepGoalMinutes = 480;
  bool _isSleeping = false;
  String _bedtime = '23:30';
  String _wakeTime = '07:00';

  // Calories & Nutrition State
  int _calorieTarget = 2000;
  int _consumedCalories = 0;
  int _burnedCalories = 0;

  // Nutrition Meal Inputs
  final _breakfastController = TextEditingController(text: 'Oats, 2 Eggs, Tea');
  final _lunchController = TextEditingController(text: '2 Roti, Dal, Rice, Salad');
  final _dinnerController = TextEditingController(text: 'Khichdi, Curd');
  int _breakfastCal = 330;
  int _lunchCal = 610;
  int _dinnerCal = 310;

  // Weather Data
  final String _weatherCity = 'Surat';
  double _weatherTemp = 28.0;
  String _weatherCondition = 'Clear';
  String _weatherRecommendation = 'Pleasant weather. Ideal for an outdoor jog or brisk walk!';

  // AI Chatbot State
  final _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  bool _isInitialSyncLoading = false;

  @override
  void initState() {
    super.initState();
    _extractUserData();

    _geminiService = GeminiService();
    _weatherService = WeatherService();
    _stepSensorService = StepSensorService();
    _sleepService = SleepService();

    _chatMessages.add({
      'sender': 'ai',
      'text': 'Hello $_userName! I am your LiveFit AI Coach. How can I help you reach your goals today?',
    });

    _initAllServices();
  }

  /// Extracts user profile information (name, goals, age, weight, height)
  /// from the passed UserModel or fallback Map object.
  void _extractUserData() {
    if (widget.user is UserModel) {
      final u = widget.user as UserModel;
      _userName = u.name;
      _userEmail = u.email;
      _age = u.age;
      _weightKg = u.weight;
      _heightCm = u.height;
      _stepGoal = u.goals.stepGoal;
      _sleepGoalMinutes = u.goals.sleepGoal;
      _calorieTarget = u.goals.calorieGoal;
    } else if (widget.user is Map<String, dynamic>) {
      final m = widget.user as Map<String, dynamic>;
      _userName = m['name']?.toString() ?? 'Athlete';
      _userEmail = m['email']?.toString() ?? '';
      _age = (m['age'] as num?)?.toInt() ?? 21;
      _weightKg = (m['weight'] as num?)?.toDouble() ?? 68.0;
      _heightCm = (m['height'] as num?)?.toDouble() ?? 175.0;
      _stepGoal = (m['goals']?['stepGoal'] as num?)?.toInt() ?? 10000;
      _sleepGoalMinutes = (m['goals']?['sleepGoal'] as num?)?.toInt() ?? 480;
      _calorieTarget = (m['goals']?['calorieGoal'] as num?)?.toInt() ?? 2000;
    } else {
      _userName = 'Athlete';
      _userEmail = '';
      _age = 21;
      _weightKg = 68.0;
      _heightCm = 175.0;
    }
  }

  /// Initializes all background services asynchronously:
  /// 1. Loads consolidated daily health stats from the database.
  /// 2. Connects hardware pedometer step stream and syncs steps to database.
  /// 3. Initializes sleep tracking service and restores active sleep sessions.
  /// 4. Fetches real-time weather recommendation for workout personalization.
  Future<void> _initAllServices() async {
    // 1. Load live data from database
    await _loadLiveMongoData();

    // 2. Step Sensor Service
    await _stepSensorService.initialize();
    if (_stepSensorService.currentDailySteps > 0 && _steps == 0) {
      setState(() => _steps = _stepSensorService.currentDailySteps);
    }
    _stepSubscription = _stepSensorService.stepStream.listen((steps) {
      if (mounted) {
        setState(() => _steps = steps);
        _apiService.syncSteps(steps: steps, source: 'sensor');
      }
    });

    // 3. Sleep Service
    await _sleepService.initialize();
    setState(() {
      _isSleeping = _sleepService.isSleeping;
      if (_sleepService.sleepMinutes > 0 && _sleepMinutes == 0) {
        _sleepMinutes = _sleepService.sleepMinutes;
        _bedtime = _sleepService.sleepTime;
        _wakeTime = _sleepService.wakeUpTime;
      }
    });

    // 4. Weather Intelligence
    try {
      final weather = await _weatherService.getWeatherRecommendation(_weatherCity);
      if (mounted) {
        setState(() {
          final tempString = weather['temp']?.toString().replaceAll('°C', '') ?? '28';
          _weatherTemp = double.tryParse(tempString) ?? 28.0;
          _weatherCondition = weather['description'] ?? 'Clear';
          _weatherRecommendation = weather['recommendation'] ?? _weatherRecommendation;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isInitialSyncLoading = false);
  }

  /// Fetches today's consolidated health metrics (steps, sleep, nutrition, burned calories, and goals)
  /// from the backend database to populate the dashboard.
  Future<void> _loadLiveMongoData() async {
    final summary = await _apiService.fetchTodayDashboard();
    if (summary != null && mounted) {
      setState(() {
        _steps = summary.steps > 0 ? summary.steps : _steps;
        _stepGoal = summary.stepGoal;
        _sleepMinutes = summary.sleepMinutes > 0 ? summary.sleepMinutes : _sleepMinutes;
        _sleepGoalMinutes = summary.sleepGoalMinutes;
        _bedtime = summary.sleepTime;
        _wakeTime = summary.wakeUpTime;
        _burnedCalories = summary.burnedCalories;
        _calorieTarget = summary.nutrition.targetCalories > 0 ? summary.nutrition.targetCalories : _calorieTarget;

        if (summary.nutrition.breakfastText.isNotEmpty) {
          _breakfastController.text = summary.nutrition.breakfastText;
          _breakfastCal = summary.nutrition.breakfastCalories;
        }
        if (summary.nutrition.lunchText.isNotEmpty) {
          _lunchController.text = summary.nutrition.lunchText;
          _lunchCal = summary.nutrition.lunchCalories;
        }
        if (summary.nutrition.dinnerText.isNotEmpty) {
          _dinnerController.text = summary.nutrition.dinnerText;
          _dinnerCal = summary.nutrition.dinnerCalories;
        }

        _consumedCalories = summary.nutrition.consumedCalories > 0
            ? summary.nutrition.consumedCalories
            : (_breakfastCal + _lunchCal + _dinnerCal);
      });
    } else {
      _calculateInitialMealsOffline();
    }
  }

  /// Calculates total consumed calories from local meal inputs when in offline fallback mode.
  void _calculateInitialMealsOffline() {
    _consumedCalories = _breakfastCal + _lunchCal + _dinnerCal;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _sleepSubscription?.cancel();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // --- HEALTH SCORE CALCULATION ---
  /// Calculates a holistic daily health score (10 to 100) combining:
  /// - Steps completion percentage (up to 35 points)
  /// - Sleep target duration ratio (up to 30 points)
  /// - Calorie intake consistency (up to 20 points)
  /// - Calorie burning through physical activity (up to 15 points)
  int get _healthScore {
    double stepPts = (_steps / _stepGoal) * 35;
    if (stepPts > 35) stepPts = 35;

    double sleepPts = (_sleepMinutes / _sleepGoalMinutes) * 30;
    if (sleepPts > 30) sleepPts = 30;

    double dietPts = 15;
    if (_consumedCalories > 0) {
      double ratio = _consumedCalories / _calorieTarget;
      if (ratio >= 0.7 && ratio <= 1.1) {
        dietPts = 20;
      } else if (ratio > 1.25 || ratio < 0.4) {
        dietPts = 10;
      }
    }

    double burnPts = (_burnedCalories / 350) * 15;
    if (burnPts > 15) burnPts = 15;

    final score = (stepPts + sleepPts + dietPts + burnPts).round().clamp(10, 100);
    return score;
  }

  /// Returns a user-friendly qualitative description corresponding to the health score tier.
  String get _healthScoreLabel {
    final score = _healthScore;
    if (score >= 85) return 'Optimal';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    return 'Needs Attention';
  }

  /// Toggles sleep session: records start time or wake time, computes duration,
  /// and synchronizes the recorded sleep metrics with the backend database.
  Future<void> _toggleSleep() async {
    if (_isSleeping) {
      final summary = await _sleepService.wakeUp();
      setState(() {
        _isSleeping = false;
        _sleepMinutes = summary.sleepMinutes;
        _wakeTime = summary.wakeUpTime;
      });

      // Synchronize sleep session with database
      await _apiService.syncSleep(
        sleepMinutes: _sleepMinutes,
        sleepGoalMinutes: _sleepGoalMinutes,
        sleepTime: _bedtime,
        wakeUpTime: _wakeTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Good morning! You slept ${_sleepMinutes ~/ 60}h ${_sleepMinutes % 60}m. ☁️'),
            backgroundColor: const Color(0xFF4F46E5),
          ),
        );
      }
    } else {
      await _sleepService.startSleep();
      setState(() {
        _isSleeping = true;
        _bedtime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sleep session started 🌙 Rest well!')),
        );
      }
    }
  }

  /// Evaluates food descriptions entered for breakfast, lunch, and dinner,
  /// computes calories using the nutritional database API, saves the daily meal records,
  /// updates total consumed calories, and recalibrates the daily health score.
  Future<void> _calculateNutritionFromDatabase() async {
    final bText = _breakfastController.text.trim();
    final lText = _lunchController.text.trim();
    final dText = _dinnerController.text.trim();

    final bCal = await _apiService.calculateMealCalories(bText);
    final lCal = await _apiService.calculateMealCalories(lText);
    final dCal = await _apiService.calculateMealCalories(dText);

    setState(() {
      _breakfastCal = bCal;
      _lunchCal = lCal;
      _dinnerCal = dCal;
      _consumedCalories = bCal + lCal + dCal;
    });

    // Persist nutrition records to backend database
    await _apiService.saveNutrition(
      breakfastText: bText,
      breakfastCalories: bCal,
      lunchText: lText,
      lunchCalories: lCal,
      dinnerText: dText,
      dinnerCalories: dCal,
    );

    await _apiService.saveHealthScore(_healthScore);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nutrition Updated! Total: $_consumedCalories kcal (Breakfast: $bCal, Lunch: $lCal, Dinner: $dCal)'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  /// Records a completed workout exercise, increments burned calorie count,
  /// and persists the workout log and updated daily stats to the database.
  Future<void> _logWorkoutDone(WorkoutItem item) async {
    setState(() {
      _burnedCalories += item.calories;
    });

    // Persist activity to database
    await _apiService.logActivity(
      activityType: item.title,
      durationMinutes: int.tryParse(item.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15,
      caloriesBurned: item.calories,
    );

    await _apiService.saveHealthScore(_healthScore);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Awesome! Completed "${item.title}" (+${item.calories} kcal burned).'),
          backgroundColor: const Color(0xFFF97316),
        ),
      );
    }
  }

  /// Adjusts the daily step count manually (e.g. via quick buttons),
  /// recalculates approximate burned calories, updates the sensor service,
  /// and synchronizes the updated steps and health score with the database.
  void _adjustSteps(int delta) {
    setState(() {
      _steps = (_steps + delta).clamp(0, 50000);
      _burnedCalories += (delta * 0.04).round();
      if (_burnedCalories < 0) _burnedCalories = 0;
    });
    _stepSensorService.setStepsManually(_steps);

    // Save updated steps to database
    _apiService.syncSteps(steps: _steps, source: 'manual');
    _apiService.saveHealthScore(_healthScore);
  }

  /// Dispatches a question or health query to the Gemini AI Coach service
  /// along with biometric snapshot context (steps, sleep, calories, weather),
  /// and displays the coach's personalized recommendation in the chat log.
  Future<void> _sendMessage([String? prefilled]) async {
    final text = prefilled ?? _chatController.text.trim();
    if (text.isEmpty) return;

    if (prefilled == null) _chatController.clear();

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text});
      _isChatLoading = true;
    });

    try {
      final reply = await _geminiService.sendChatMessage(
        message: text,
        userContext: {
          'name': _userName,
          'steps': _steps,
          'stepGoal': _stepGoal,
          'sleepMinutes': _sleepMinutes,
          'consumedCalories': _consumedCalories,
          'burnedCalories': _burnedCalories,
          'age': _age,
          'weight': _weightKg,
          'weather': '$_weatherTemp°C, $_weatherCondition',
        },
      );

      if (mounted) {
        setState(() {
          _chatMessages.add({'sender': 'ai', 'text': reply});
          _isChatLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chatMessages.add({'sender': 'ai', 'text': 'Keep up the healthy habits and stay hydrated!'});
          _isChatLoading = false;
        });
      }
    }
  }

  /// Navigates to the user's Profile & Settings screen to customize daily step/sleep goals,
  /// view BMI metrics, manage connected hardware, or log out of the account.
  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: {
            'name': _userName,
            'email': _userEmail,
            'age': _age,
            'weight': _weightKg,
            'height': _heightCm,
            'goals': {
              'stepGoal': _stepGoal,
              'sleepGoal': _sleepGoalMinutes,
              'calorieGoal': _calorieTarget,
            },
          },
          onLogout: () async {
            await _authService.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
            );
          },
          onGoalsUpdated: (newStepGoal, newSleepGoal) {
            setState(() {
              _stepGoal = newStepGoal;
              _sleepGoalMinutes = newSleepGoal;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingCalories = _calorieTarget - _consumedCalories + _burnedCalories;
    final workoutList = WorkoutEngine.generateRecommendations(
      age: _age,
      weightKg: _weightKg,
      weatherCondition: _weatherCondition,
      tempC: _weatherTemp,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text('LiveFit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile & Settings',
            icon: const Icon(Icons.account_circle_rounded, size: 28),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: _isInitialSyncLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF97316)),
                  SizedBox(height: 16),
                  Text('Loading your health summary...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLiveMongoData,
              color: const Color(0xFFF97316),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $_userName 👋',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const Text(
                              "Here is your daily health overview for today",
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SECTION 1: DAILY HEALTH SCORE
                    _buildSectionHeader('1. Daily Health Score', Icons.psychology_rounded),
                    _buildHealthScoreCard(),
                    const SizedBox(height: 22),

                    // SECTION 2: STEP COUNT
                    _buildSectionHeader('2. Step Count & Walking', Icons.directions_walk_rounded),
                    _buildStepCard(),
                    const SizedBox(height: 22),

                    // SECTION 3: SLEEP TRACKING
                    _buildSectionHeader('3. Sleep Tracking', Icons.nightlight_round),
                    _buildSleepCard(),
                    const SizedBox(height: 22),

                    // SECTION 4: CALORIES SUMMARY
                    _buildSectionHeader('4. Calories (kcal)', Icons.local_fire_department_rounded),
                    _buildCaloriesCard(remainingCalories),
                    const SizedBox(height: 22),

                    // SECTION 5: RECOMMENDED WORKOUTS
                    _buildSectionHeader('5. Recommended Workouts for You', Icons.fitness_center_rounded),
                    _buildWorkoutSection(workoutList),
                    const SizedBox(height: 22),

                    // SECTION 6: NUTRITION CALCULATOR
                    _buildSectionHeader('6. Nutrition & Meal Calculator', Icons.restaurant_rounded),
                    _buildNutritionSection(),
                    const SizedBox(height: 22),

                    // SECTION 7: WEATHER INTELLIGENCE
                    _buildSectionHeader('7. Weather Intelligence', Icons.wb_sunny_rounded),
                    _buildWeatherCard(),
                    const SizedBox(height: 22),

                    // SECTION 8: AI SUGGESTIONS
                    _buildSectionHeader('8. AI Suggestions', Icons.auto_awesome_rounded),
                    _buildAiSuggestionsCard(),
                    const SizedBox(height: 22),

                    // SECTION 9: AI COACH CHAT
                    _buildSectionHeader('9. AI Coach Assistant Chat', Icons.chat_rounded),
                    _buildChatCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF97316)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: _healthScore / 100.0,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFFFEDD5),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_healthScore',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const Text('/100', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rating: $_healthScoreLabel',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Synthesized from your steps, sleep hours, calorie balance, and exercise.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard() {
    final progress = (_steps / _stepGoal).clamp(0.0, 1.0);
    final distanceKm = (_steps * 0.000762).toStringAsFixed(2);
    final burnedFromSteps = (_steps * 0.04).toStringAsFixed(0);
    final isSensorActive = _stepSensorService.isSensorActive;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_steps',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text('Goal: $_stepGoal steps', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSensorActive ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSensorActive ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, size: 14, color: isSensorActive ? const Color(0xFF059669) : const Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        isSensorActive ? 'Hardware Sensor Live' : 'Pedometer Ready',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSensorActive ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance: $distanceKm km', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                Text('Burned: $burnedFromSteps kcal', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _adjustSteps(-500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: const Text('-500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _adjustSteps(500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    final hours = _sleepMinutes ~/ 60;
    final mins = _sleepMinutes % 60;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hours}h ${mins}m',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text('Last rest: $_bedtime → $_wakeTime', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _toggleSleep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSleeping ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: Icon(_isSleeping ? Icons.wb_sunny_rounded : Icons.bedtime_rounded, size: 16),
                  label: Text(_isSleeping ? 'Wake Up ☀️' : 'Start Sleep 🌙', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _isSleeping
                  ? 'Active sleep recording in progress... Good night!'
                  : 'Target is ${_sleepGoalMinutes ~/ 60} hours. Regular sleep restores physical muscle and mental focus.',
              style: TextStyle(
                fontSize: 12,
                color: _isSleeping ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                fontWeight: _isSleeping ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesCard(int remaining) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalorieStat('Budget', '$_calorieTarget', Colors.blue),
                _buildCalorieStat('Food', '$_consumedCalories', Colors.orange),
                _buildCalorieStat('Burned', '$_burnedCalories', Colors.green),
                _buildCalorieStat('Remaining', '$remaining', remaining >= 0 ? const Color(0xFF0D9488) : Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_consumedCalories / _calorieTarget).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildWorkoutSection(List<WorkoutItem> workouts) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: Color(0xFFF97316)),
                const SizedBox(width: 6),
                Text(
                  'Tailored for Age $_age, Weight ${_weightKg.toInt()}kg & $_weatherTemp°C Weather',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...workouts.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(w.icon, color: const Color(0xFFF97316), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            Text(w.reason, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text('${w.duration} • ~${w.calories} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _logWorkoutDone(w),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(60, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your meals below to calculate nutrition & calories:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            _buildMealInputField(
              label: 'Morning Breakfast',
              icon: Icons.free_breakfast_rounded,
              controller: _breakfastController,
              calories: _breakfastCal,
            ),
            const SizedBox(height: 12),

            _buildMealInputField(
              label: 'Lunch',
              icon: Icons.lunch_dining_rounded,
              controller: _lunchController,
              calories: _lunchCal,
            ),
            const SizedBox(height: 12),

            _buildMealInputField(
              label: 'Dinner',
              icon: Icons.dinner_dining_rounded,
              controller: _dinnerController,
              calories: _dinnerCal,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _calculateNutritionFromDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Calculate Calories & Update Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required int calories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFF97316)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            Text(
              '$calories kcal',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'e.g. 2 Roti, Dal, Rice',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF0284C7), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$_weatherCity, ${_weatherTemp.toStringAsFixed(0)}°C',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 8),
                      Text('($_weatherCondition)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weatherRecommendation,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSuggestionsCard() {
    final stepRemaining = (_stepGoal - _steps).clamp(0, 50000);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAiTipRow(
              Icons.directions_walk_rounded,
              'Steps Goal',
              stepRemaining > 0
                  ? 'You are $stepRemaining steps away from your daily goal. An evening walk will get you there!'
                  : 'Target reached! Fantastic job maintaining daily activity.',
            ),
            const Divider(height: 18),
            _buildAiTipRow(
              Icons.bedtime_rounded,
              'Sleep Recovery',
              'Consistent 7-8 hour sleep schedules accelerate metabolic recovery and boost daytime focus.',
            ),
            const Divider(height: 18),
            _buildAiTipRow(
              Icons.restaurant_rounded,
              'Diet Balance',
              'Ensure adequate protein intake with every meal to aid muscle repair after workouts.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTipRow(IconData icon, String title, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF97316)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(tip, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Coach Assistant Chat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Smart Coach Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPromptChip('15-min Workout 🏋️'),
                _buildPromptChip('How am I doing? 📊'),
                _buildPromptChip('Suggest Healthy Dinner 🥗'),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.builder(
                itemCount: _chatMessages.length,
                itemBuilder: (ctx, i) {
                  final msg = _chatMessages[i];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFF97316) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask coach a fitness question...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isChatLoading ? null : () => _sendMessage(),
                  icon: _isChatLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Color(0xFFF97316)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return InkWell(
      onTap: () => _sendMessage(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
        ),
      ),
    );
  }
}
