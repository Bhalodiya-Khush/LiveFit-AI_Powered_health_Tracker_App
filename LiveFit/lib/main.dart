import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/gemini_service.dart';
import 'services/weather_service.dart';
import 'services/step_sensor_service.dart';
import 'services/sleep_service.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Root Application Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveFit - Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          primary: const Color(0xFFF97316),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

// ============================================================================
// SIMPLE FOOD DATABASE & CALORIE CALCULATOR
// Matches food items from user input and calculates total calories.
// ============================================================================
class FoodDatabase {
  static final Map<String, int> foodCalories = {
    // Breakfast items
    'oats': 150,
    'oatmeal': 150,
    'egg': 70,
    'eggs': 140,
    'boiled egg': 70,
    'omelette': 160,
    'toast': 80,
    'bread': 80,
    'tea': 40,
    'coffee': 50,
    'milk': 120,
    'poha': 180,
    'upma': 200,
    'idli': 90,
    'dosa': 170,
    'paratha': 260,
    'apple': 95,
    'banana': 105,
    'fruits': 100,
    'cereal': 130,
    'pancakes': 220,

    // Lunch items
    'rice': 200,
    'brown rice': 210,
    'roti': 100,
    'chapati': 100,
    'dal': 150,
    'paneer': 260,
    'chicken': 240,
    'chicken curry': 280,
    'salad': 60,
    'curd': 90,
    'yogurt': 100,
    'rajma': 240,
    'chole': 250,
    'subzi': 120,
    'vegetables': 100,
    'sandwich': 250,

    // Dinner items
    'khichdi': 220,
    'soup': 90,
    'fish': 200,
    'pasta': 280,
    'wrap': 260,
    'grilled chicken': 220,
    'sprouts': 80,
  };

  /// Parses text like "2 roti, dal, rice" and calculates total calories
  static int calculateCalories(String input) {
    if (input.trim().isEmpty) return 0;
    int total = 0;
    final items = input.split(RegExp(r'[,+]'));
    for (var item in items) {
      final clean = item.trim().toLowerCase();
      if (clean.isEmpty) continue;

      // Extract multiplier if any (e.g., "2 eggs", "3 roti")
      final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(clean);
      int quantity = 1;
      String foodName = clean;
      if (match != null) {
        quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        foodName = match.group(2)?.trim() ?? clean;
      }

      int? cal = foodCalories[foodName];
      if (cal == null) {
        // Try partial keyword match
        for (var entry in foodCalories.entries) {
          if (foodName.contains(entry.key) || entry.key.contains(foodName)) {
            cal = entry.value;
            break;
          }
        }
      }

      // Default estimate if unknown food
      cal ??= 120;
      total += (cal * quantity);
    }
    return total;
  }
}

// ============================================================================
// WORKOUT RECOMMENDATION MODEL & ENGINE
// Suggests 2-3 exercises tailored to Age, Weight, and Weather condition.
// ============================================================================
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
}

List<WorkoutItem> generateWorkoutRecommendations({
  required int age,
  required double weightKg,
  required String weatherCondition,
  required double tempC,
}) {
  final isIndoor = tempC > 34 || tempC < 12 || ['Rain', 'Snow', 'Thunderstorm', 'Drizzle'].contains(weatherCondition);

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
        reason: 'Joint-friendly strength circuit tailored for your $weightKg kg body weight.',
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
        reason: 'Burns excess calories and builds leg stamina for $weightKg kg profile.',
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

// ============================================================================
// SIMPLE AUTHENTICATION SERVICE
// Clean login and signup logic with local offline fallback.
// ============================================================================
class AuthService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Fallback local mock user so student can always demonstrate the app offline
    return {
      'token': 'demo_token_123',
      'user': {
        'name': email.split('@').first,
        'email': email,
        'age': 21,
        'weight': 68.0,
        'height': 175.0,
        'goals': {'stepGoal': 10000, 'sleepGoal': 480},
      },
    };
  }

  Future<Map<String, dynamic>?> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Fallback local mock account
    return {
      'token': 'demo_token_123',
      'user': {
        'name': name,
        'email': email,
        'age': 21,
        'weight': 68.0,
        'height': 175.0,
        'goals': {'stepGoal': 10000, 'sleepGoal': 480},
      },
    };
  }
}

// ============================================================================
// AUTH SCREEN (LOGIN & SIGNUP)
// ============================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController(text: 'Khush');
  final _emailController = TextEditingController(text: 'khush@livefit.com');
  final _passwordController = TextEditingController(text: 'password123');

  void _submit() async {
    final auth = AuthService();
    final result = _isLogin
        ? await auth.login(email: _emailController.text, password: _passwordController.text)
        : await auth.createAccount(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (result != null) {
      final user = result['user'] as Map<String, dynamic>? ?? {
        'name': _nameController.text,
        'email': _emailController.text,
        'age': 21,
        'weight': 68.0,
        'height': 175.0,
      };

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center_rounded, size: 54, color: Color(0xFFF97316)),
              ),
              const SizedBox(height: 16),
              const Text('LiveFit', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(_isLogin ? 'Welcome back' : 'Create Account', style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Create account' : 'Already have an account? Sign In',
                          style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN DASHBOARD SCREEN (ONE SINGLE MAIN PAGE)
// Contains all 9 essential health tracking sections in one scrollable page.
// ============================================================================
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

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
  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<bool>? _sleepSubscription;

  // Health Stats & State
  int _steps = 6420;
  int _stepGoal = 10000;
  int _sleepMinutes = 450; // 7 hours 30 mins
  int _sleepGoalMinutes = 480; // 8 hours
  bool _isSleeping = false;
  String _bedtime = '23:30';
  String _wakeTime = '07:00';

  // Calories & Nutrition State
  final int _calorieTarget = 2000;
  int _consumedCalories = 1250;
  int _burnedCalories = 380;

  // Nutrition Meal Inputs
  final _breakfastController = TextEditingController(text: 'Oats, 2 Eggs, Tea');
  final _lunchController = TextEditingController(text: '2 Roti, Dal, Rice, Salad');
  final _dinnerController = TextEditingController(text: 'Khichdi, Curd');
  int _breakfastCal = 330;
  int _lunchCal = 610;
  int _dinnerCal = 310;

  // User Profile Data
  late int _age;
  late double _weightKg;

  // Weather Data
  final String _weatherCity = 'Surat';
  double _weatherTemp = 28.0;
  String _weatherCondition = 'Clear';
  String _weatherRecommendation = 'Pleasant weather. Ideal for a 20-minute outdoor jog or brisk walk!';

  // AI Chatbot State
  final _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _age = (widget.user['age'] as num?)?.toInt() ?? 21;
    _weightKg = (widget.user['weight'] as num?)?.toDouble() ?? 68.0;
    _stepGoal = (widget.user['goals']?['stepGoal'] as num?)?.toInt() ?? 10000;
    _sleepGoalMinutes = (widget.user['goals']?['sleepGoal'] as num?)?.toInt() ?? 480;

    _geminiService = GeminiService();
    _weatherService = WeatherService();
    _stepSensorService = StepSensorService();
    _sleepService = SleepService();

    _chatMessages.add({
      'sender': 'ai',
      'text': 'Hello ${widget.user['name'] ?? 'User'}! I am your LiveFit AI Coach. How can I help you reach your goals today?',
    });

    _initServices();
    _calculateInitialMeals();
  }

  void _calculateInitialMeals() {
    _breakfastCal = FoodDatabase.calculateCalories(_breakfastController.text);
    _lunchCal = FoodDatabase.calculateCalories(_lunchController.text);
    _dinnerCal = FoodDatabase.calculateCalories(_dinnerController.text);
    _consumedCalories = _breakfastCal + _lunchCal + _dinnerCal;
  }

  Future<void> _initServices() async {
    // 1. Initialize Step Sensor
    await _stepSensorService.initialize();
    if (_stepSensorService.currentDailySteps > 0) {
      setState(() => _steps = _stepSensorService.currentDailySteps);
    }
    _stepSubscription = _stepSensorService.stepStream.listen((steps) {
      if (mounted) setState(() => _steps = steps);
    });

    // 2. Initialize Sleep Service
    await _sleepService.initialize();
    setState(() {
      _isSleeping = _sleepService.isSleeping;
      _sleepMinutes = _sleepService.sleepMinutes;
      _bedtime = _sleepService.sleepTime;
      _wakeTime = _sleepService.wakeUpTime;
    });

    // 3. Load Weather Data
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
  int get _healthScore {
    // 1. Steps Score (up to 35)
    double stepPts = (_steps / _stepGoal) * 35;
    if (stepPts > 35) stepPts = 35;

    // 2. Sleep Score (up to 30)
    double sleepPts = (_sleepMinutes / _sleepGoalMinutes) * 30;
    if (sleepPts > 30) sleepPts = 30;

    // 3. Nutrition Score (up to 20)
    double dietPts = 15;
    if (_consumedCalories > 0) {
      double ratio = _consumedCalories / _calorieTarget;
      if (ratio >= 0.7 && ratio <= 1.1) {
        dietPts = 20;
      } else if (ratio > 1.25 || ratio < 0.4) {
        dietPts = 10;
      }
    }

    // 4. Burned Calories & Workout Score (up to 15)
    double burnPts = (_burnedCalories / 350) * 15;
    if (burnPts > 15) burnPts = 15;

    return (stepPts + sleepPts + dietPts + burnPts).round().clamp(10, 100);
  }

  String get _healthScoreLabel {
    final score = _healthScore;
    if (score >= 85) return 'Optimal';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    return 'Needs Attention';
  }

  // --- SLEEP ACTIONS ---
  Future<void> _toggleSleep() async {
    if (_isSleeping) {
      final summary = await _sleepService.wakeUp();
      setState(() {
        _isSleeping = false;
        _sleepMinutes = summary.sleepMinutes;
        _wakeTime = summary.wakeUpTime;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Good morning! You slept ${_sleepMinutes ~/ 60}h ${_sleepMinutes % 60}m.')),
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
          const SnackBar(content: Text('Sleep session started 🌙 Sleep well!')),
        );
      }
    }
  }

  // --- NUTRITION CALCULATION ---
  void _calculateNutritionFromDatabase() {
    setState(() {
      _breakfastCal = FoodDatabase.calculateCalories(_breakfastController.text);
      _lunchCal = FoodDatabase.calculateCalories(_lunchController.text);
      _dinnerCal = FoodDatabase.calculateCalories(_dinnerController.text);
      _consumedCalories = _breakfastCal + _lunchCal + _dinnerCal;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nutrition Updated! Total: $_consumedCalories kcal (Breakfast: $_breakfastCal, Lunch: $_lunchCal, Dinner: $_dinnerCal)'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  // --- WORKOUT ACTION ---
  void _logWorkoutDone(WorkoutItem item) {
    setState(() {
      _burnedCalories += item.calories;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Awesome! Completed "${item.title}" (+${item.calories} kcal burned).'),
        backgroundColor: const Color(0xFFF97316),
      ),
    );
  }

  // --- STEP ADJUSTMENT ---
  void _adjustSteps(int delta) {
    setState(() {
      _steps = (_steps + delta).clamp(0, 50000);
      _burnedCalories += (delta * 0.04).round();
      if (_burnedCalories < 0) _burnedCalories = 0;
    });
    _stepSensorService.setStepsManually(_steps);
  }

  // --- AI CHATBOT MESSAGE ---
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
          'name': widget.user['name'] ?? 'User',
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
          _chatMessages.add({'sender': 'ai', 'text': 'I am currently operating offline. Keep moving and stay hydrated!'});
          _isChatLoading = false;
        });
      }
    }
  }

  // --- OPEN PROFILE SCREEN ---
  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: {
            ...widget.user,
            'age': _age,
            'weight': _weightKg,
            'goals': {'stepGoal': _stepGoal, 'sleepGoal': _sleepGoalMinutes},
          },
          onLogout: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
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
    final workoutList = generateWorkoutRecommendations(
      age: _age,
      weightKg: _weightKg,
      weatherCondition: _weatherCondition,
      tempC: _weatherTemp,
    );

    return Scaffold(
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
            tooltip: 'View Profile & Goals',
            icon: const Icon(Icons.account_circle_rounded, size: 28),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Hello, ${widget.user['name'] ?? 'Athlete'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const Text(
              "Here is your daily health overview for today",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // ================================================================
            // SECTION 1: DAILY HEALTH SCORE
            // ================================================================
            _buildSectionHeader('1. Daily Health Score', Icons.psychology_rounded),
            _buildHealthScoreCard(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 2: STEP COUNT (WITH SENSOR)
            // ================================================================
            _buildSectionHeader('2. Step Count & Walking', Icons.directions_walk_rounded),
            _buildStepCard(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 3: SLEEP TRACKING
            // ================================================================
            _buildSectionHeader('3. Sleep Tracking', Icons.nightlight_round),
            _buildSleepCard(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 4: CALORIES (KCAL) SUMMARY
            // ================================================================
            _buildSectionHeader('4. Calories (kcal)', Icons.local_fire_department_rounded),
            _buildCaloriesCard(remainingCalories),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 5: RECOMMENDED WORKOUTS (TAILORED TO AGE, WEIGHT & WEATHER)
            // ================================================================
            _buildSectionHeader('5. Recommended Workouts for You', Icons.fitness_center_rounded),
            _buildWorkoutSection(workoutList),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 6: NUTRITION & FOOD DATABASE CALORIES
            // ================================================================
            _buildSectionHeader('6. Nutrition & Meal Calculator', Icons.restaurant_rounded),
            _buildNutritionSection(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 7: WEATHER INTELLIGENCE
            // ================================================================
            _buildSectionHeader('7. Weather Intelligence', Icons.wb_sunny_rounded),
            _buildWeatherCard(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 8: AI SUGGESTIONS
            // ================================================================
            _buildSectionHeader('8. AI Suggestions', Icons.auto_awesome_rounded),
            _buildAiSuggestionsCard(),
            const SizedBox(height: 22),

            // ================================================================
            // SECTION 9: AI COACH ASSISTANT CHAT
            // ================================================================
            _buildSectionHeader('9. AI Coach Assistant Chat', Icons.chat_rounded),
            _buildChatCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- SECTION HEADER HELPER ---
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

  // ==========================================================================
  // WIDGET 1: HEALTH SCORE CARD
  // ==========================================================================
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
            // Circular Score Gauge
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
            // Score Description & Status
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

  // ==========================================================================
  // WIDGET 2: STEP COUNT CARD
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 3: SLEEP TRACKING CARD
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 4: CALORIES SUMMARY CARD
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 5: WORKOUTS TAILORED TO AGE, WEIGHT & WEATHER
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 6: NUTRITION & FOOD DATABASE CALCULATOR
  // ==========================================================================
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
              'Enter your meals below to calculate calories from database:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            // Morning Breakfast
            _buildMealInputField(
              label: 'Morning Breakfast',
              icon: Icons.free_breakfast_rounded,
              controller: _breakfastController,
              calories: _breakfastCal,
            ),
            const SizedBox(height: 12),

            // Lunch
            _buildMealInputField(
              label: 'Lunch',
              icon: Icons.lunch_dining_rounded,
              controller: _lunchController,
              calories: _lunchCal,
            ),
            const SizedBox(height: 12),

            // Dinner
            _buildMealInputField(
              label: 'Dinner',
              icon: Icons.dinner_dining_rounded,
              controller: _dinnerController,
              calories: _dinnerCal,
            ),
            const SizedBox(height: 16),

            // Calculate Button
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

  // ==========================================================================
  // WIDGET 7: WEATHER INTELLIGENCE CARD
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 8: AI SUGGESTIONS CARD
  // ==========================================================================
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

  // ==========================================================================
  // WIDGET 9: AI COACH ASSISTANT CHAT CARD
  // ==========================================================================
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

            // Quick Prompt Chips
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

            // Chat Messages Container
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

            // Chat Input Field
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

// ============================================================================
// STEP TRACKING SCREEN (FOR DETAILED STEP SENSOR VIEW)
// ============================================================================
class StepTrackingScreen extends StatefulWidget {
  final int initialSteps;
  final int goalSteps;
  final StepSensorService? stepSensorService;
  final ValueChanged<int>? onChanged;

  const StepTrackingScreen({
    super.key,
    required this.initialSteps,
    required this.goalSteps,
    this.stepSensorService,
    this.onChanged,
  });

  @override
  State<StepTrackingScreen> createState() => _StepTrackingScreenState();
}

class _StepTrackingScreenState extends State<StepTrackingScreen> {
  late int _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.initialSteps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Step Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_steps', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            Text('Goal: ${widget.goalSteps} steps', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() => _steps += 500);
              },
              child: const Text('+500'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                widget.onChanged?.call(_steps);
              },
              child: const Text('Save & Apply Steps'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SLEEP TRACKING SCREEN (FOR DETAILED SLEEP QUALITY VIEW)
// ============================================================================
class SleepTrackingScreen extends StatefulWidget {
  final SleepService sleepService;
  final int initialMinutes;
  final int initialGoalMinutes;
  final String initialSleepTime;
  final String initialWakeUpTime;
  final ValueChanged<SleepRecord>? onSleepUpdated;

  const SleepTrackingScreen({
    super.key,
    required this.sleepService,
    this.initialMinutes = 450,
    this.initialGoalMinutes = 480,
    this.initialSleepTime = '23:00',
    this.initialWakeUpTime = '07:00',
    this.onSleepUpdated,
  });

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  late bool _isSleeping;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _isSleeping = widget.sleepService.isSleeping;
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final hours = _minutes ~/ 60;
    final mins = _minutes % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracking & Analytics')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Track Overnight Rest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('${hours}h ${mins}m', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_isSleeping) ...[
              const Text('SLEEP SESSION IN PROGRESS', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final rec = await widget.sleepService.wakeUp();
                  setState(() => _isSleeping = false);
                  widget.onSleepUpdated?.call(rec);
                },
                child: const Text('Wake Up & Save Sleep ☀️'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () async {
                  await widget.sleepService.startSleep();
                  setState(() => _isSleeping = true);
                },
                child: const Text('Start Sleep Session 🌙'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AI COACH CHAT SCREEN (FULL-SCREEN COACH CHAT)
// ============================================================================
class AICoachChatScreen extends StatefulWidget {
  final GeminiService geminiService;
  final List<Map<String, String>> chatHistory;
  final Map<String, dynamic> userContext;
  final ValueChanged<String>? onSendMessage;
  final VoidCallback? onClearChat;
  final VoidCallback? onOpenSettings;

  const AICoachChatScreen({
    super.key,
    required this.geminiService,
    required this.chatHistory,
    required this.userContext,
    this.onSendMessage,
    this.onClearChat,
    this.onOpenSettings,
  });

  @override
  State<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends State<AICoachChatScreen> {
  final _controller = TextEditingController();
  late List<Map<String, String>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.chatHistory);
  }

  void _send(String text) async {
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _messages.add({'role': 'user', 'text': text}));
    final reply = await widget.geminiService.sendChatMessage(
      message: text,
      userContext: widget.userContext,
    );
    if (mounted) {
      setState(() => _messages.add({'role': 'ai', 'text': reply}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.userContext['steps'] ?? 0;
    final stepGoal = widget.userContext['stepGoal'] ?? 10000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveFit AI Coach'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF7ED),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF97316), size: 16),
                const SizedBox(width: 8),
                Text('$steps / $stepGoal steps today', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(_messages[i]['text'] ?? ''),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask coach...'),
                    onSubmitted: _send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

