import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _prefKey = 'livefit_gemini_api_key';
  static const String _defaultPlaceholderKey = 'gen-lang-client-0701528390';

  String _apiKey;

  GeminiService({String? apiKey})
      : _apiKey = apiKey ??
            const String.fromEnvironment(
              'GEMINI_API_KEY',
              defaultValue: '',
            );

  String get currentApiKey => _apiKey;

  bool get hasValidApiKey {
    final key = _apiKey.trim();
    return key.isNotEmpty &&
        key != _defaultPlaceholderKey &&
        !key.startsWith('gen-lang-client');
  }

  /// Initialize and load saved API key from SharedPreferences if available
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _apiKey = savedKey.trim();
      }
    } catch (_) {
      // Ignored if prefs not ready
    }
  }

  /// Save custom Gemini API key to local storage
  Future<void> setCustomApiKey(String newKey) async {
    _apiKey = newKey.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_apiKey.isEmpty) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, _apiKey);
      }
    } catch (_) {}
  }

  /// Interactive Chatbot Conversation
  /// Handles multi-turn messages, user stats context, Gemini API, and offline fallback.
  Future<String> sendChatMessage({
    required String message,
    List<Map<String, String>> chatHistory = const [],
    Map<String, dynamic>? userContext,
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      return "How can I help you with your health and fitness today?";
    }

    // Try Gemini API if a valid key is provided
    if (hasValidApiKey) {
      try {
        final geminiResponse = await _callGeminiApi(cleanMessage, chatHistory, userContext);
        if (geminiResponse != null && geminiResponse.trim().isNotEmpty) {
          return geminiResponse.trim();
        }
      } catch (_) {
        // Fall through to local intelligent coach engine
      }
    }

    // Fallback to our Intelligent Local Health Coach AI Engine
    return _generateLocalCoachResponse(cleanMessage, userContext);
  }

  /// Generate personalized health insight for dashboard
  Future<String> getHealthInsight({
    required int steps,
    required int sleepMinutes,
    required double waterLiters,
  }) async {
    final prompt = '''
You are a friendly health coach for a fitness app called LiveFit.
User stats:
- Steps today: $steps
- Sleep: ${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m
- Water: ${waterLiters.toStringAsFixed(1)} L

Give a short motivational health update in 2 sentences. Recommend one action to improve their health today.
''';

    if (hasValidApiKey) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      } catch (_) {}
    }

    // Dynamic smart local insight
    final sleepHours = sleepMinutes / 60.0;
    if (steps >= 10000 && sleepHours >= 7.0) {
      return "Outstanding effort! You've crushed 10,000+ steps and got solid sleep. Maintain hydration with another glass of water and enjoy your active recovery!";
    } else if (steps >= 7000) {
      return "Great momentum today with ${steps.toString()} steps! Take a short evening stroll to reach your goal and aim for 8 hours of restorative sleep tonight.";
    } else if (sleepHours < 6.0 && sleepMinutes > 0) {
      return "You logged ${sleepHours.toStringAsFixed(1)}h of sleep today. Prioritize a lighter workout or yoga today, and hydrate consistently to keep your energy sharp.";
    } else {
      return "You are at ${steps.toString()} steps today. A brisk 20-minute walk and hydrating with 500ml water right now will give you an instant energy boost!";
    }
  }

  /// Call Gemini 2.0 / 1.5 Flash via REST API
  Future<String?> _callGeminiApi(
    String userMessage,
    List<Map<String, String>> history,
    Map<String, dynamic>? userContext,
  ) async {
    final systemPrompt = _buildSystemPrompt(userContext);

    // Prepare contents formatted for Gemini API
    final List<Map<String, dynamic>> contents = [];

    // Add recent conversation history (up to last 6 turns)
    final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final item in recentHistory) {
      final role = item['role'] == 'user' ? 'user' : 'model';
      final text = item['text'] ?? '';
      if (text.isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [
            {'text': text}
          ],
        });
      }
    }

    // Append current message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 500,
      }
    };

    final models = ['gemini-2.0-flash', 'gemini-1.5-flash'];
    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final candidateText =
              decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (candidateText is String && candidateText.trim().isNotEmpty) {
            return candidateText.trim();
          }
        }
      } catch (_) {
        // Try next model if any
      }
    }

    return null;
  }

  String _buildSystemPrompt(Map<String, dynamic>? userContext) {
    final buffer = StringBuffer(
      'You are LiveFit AI Coach, a supportive, certified fitness trainer and wellness guide. '
      'Help users with workouts, nutrition, step goals, sleep, hydration, and healthy lifestyle habits. '
      'Keep your tone motivating, friendly, and practical. Keep responses under 4 sentences or concise bullet points unless asked for a complete plan. Do not prescribe medical treatments.\n\n',
    );

    if (userContext != null) {
      buffer.writeln('Live User Context:');
      if (userContext['name'] != null) buffer.writeln('- Name: ${userContext['name']}');
      if (userContext['steps'] != null) buffer.writeln('- Steps today: ${userContext['steps']} / goal: ${userContext['stepGoal'] ?? 10000}');
      if (userContext['sleepMinutes'] != null) {
        final m = userContext['sleepMinutes'] as int;
        buffer.writeln('- Sleep logged: ${m ~/ 60}h ${m % 60}m');
      }
      if (userContext['waterLiters'] != null) buffer.writeln('- Water intake: ${userContext['waterLiters']} L');
      if (userContext['weatherTemp'] != null) buffer.writeln('- Current weather: ${userContext['weatherTemp']}, ${userContext['weatherCondition'] ?? ''}');
    }

    return buffer.toString();
  }

  /// Intelligent Local Health Coach AI Engine
  /// Provides instant, high-quality, contextual advice when offline or without an API key.
  String _generateLocalCoachResponse(String query, Map<String, dynamic>? userContext) {
    final q = query.toLowerCase();

    final steps = (userContext?['steps'] as num?)?.toInt() ?? 8420;
    final stepGoal = (userContext?['stepGoal'] as num?)?.toInt() ?? 10000;
    final sleepMins = (userContext?['sleepMinutes'] as num?)?.toInt() ?? 420;
    final waterLiters = (userContext?['waterLiters'] as num?)?.toDouble() ?? 2.1;
    final name = (userContext?['name'] as String?) ?? 'Athlete';
    final weatherTemp = (userContext?['weatherTemp'] as String?) ?? '28°C';

    // 1. Personalized Progress / "How am I doing?"
    if (q.contains('how am i doing') ||
        q.contains('my progress') ||
        q.contains('my stats') ||
        q.contains('today summary') ||
        q.contains('my score') ||
        q.contains('status')) {
      final remainingSteps = stepGoal - steps;
      final stepPercent = ((steps / stepGoal) * 100).clamp(0, 100).toInt();
      final sleepHours = sleepMins ~/ 60;
      final sleepRemainder = sleepMins % 60;

      String stepStatus = remainingSteps <= 0
          ? "🎯 You've surpassed your daily goal of $stepGoal steps!"
          : "👟 You're at $steps / $stepGoal steps ($stepPercent%). Just $remainingSteps steps left to hit your goal!";

      return "Here is your live daily snapshot, $name:\n\n"
          "• Steps: $stepStatus\n"
          "• Sleep: ${sleepHours}h ${sleepRemainder}m recorded.\n"
          "• Hydration: ${waterLiters.toStringAsFixed(1)}L logged.\n\n"
          "${remainingSteps > 0 ? 'A quick 15-minute walk will easily close that step gap!' : 'Incredible dedication today!'} Keep up the high energy!";
    }

    // 2. Nutrition, Diet & Food
    if (q.contains('eat') ||
        q.contains('food') ||
        q.contains('diet') ||
        q.contains('nutrition') ||
        q.contains('protein') ||
        q.contains('meal') ||
        q.contains('snack') ||
        q.contains('calories') ||
        q.contains('breakfast') ||
        q.contains('dinner') ||
        q.contains('lunch')) {
      if (q.contains('post') || q.contains('after workout') || q.contains('after exercise') || q.contains('after training')) {
        return "Great post-workout fuel needs protein + carbohydrates within 45 minutes:\n\n"
            "• Option 1: Greek yogurt or cottage cheese with berries & honey\n"
            "• Option 2: Grilled chicken breast with sweet potatoes / brown rice\n"
            "• Option 3: Protein shake blended with 1 banana and a spoonful of peanut butter\n\n"
            "Don't forget 500ml of water to rehydrate lost fluids!";
      }

      if (q.contains('pre') || q.contains('before workout') || q.contains('before exercise')) {
        return "Ideal Pre-Workout Fuel (30-60 mins prior):\n\n"
            "• A medium banana with a tablespoon of peanut or almond butter\n"
            "• A small bowl of oatmeal with sliced fruit\n"
            "• Whole-grain toast with boiled egg or hummus\n\n"
            "Keep it light on fats and rich in easily digestible carbs for sustained energy!";
      }

      if (q.contains('protein')) {
        return "Protein Target Guideline:\n\n"
            "• Aim for 1.4 to 2.0 grams of protein per kg of body weight if you exercise regularly.\n"
            "• Top Sources: Eggs, chicken, fish, tofu, lentils, Greek yogurt, paneer, and whey protein.\n"
            "• Spread protein evenly across 3-4 meals to optimize muscle protein synthesis.";
      }

      return "Healthy Nutrition Principles:\n\n"
          "• Plate Rule: Half your plate with colorful veggies, a quarter with lean protein, and a quarter with complex carbs.\n"
          "• Hydration: Drink a glass of water 20 minutes before each meal.\n"
          "• Snack Smart: Choose almonds, boiled eggs, or fresh fruit over processed chips and sugary drinks.";
    }

    // 3. Workout & Exercise Recommendations
    if (q.contains('workout') ||
        q.contains('exercise') ||
        q.contains('routine') ||
        q.contains('training') ||
        q.contains('gym') ||
        q.contains('hiit') ||
        q.contains('cardio') ||
        q.contains('pushup') ||
        q.contains('squat')) {
      if (q.contains('home') || q.contains('quick') || q.contains('no equipment') || q.contains('bodyweight')) {
        return "Here is a quick 15-Minute Full-Body Home Circuit:\n\n"
            "1. Bodyweight Squats: 3 sets x 15 reps\n"
            "2. Push-ups (or knee push-ups): 3 sets x 10-12 reps\n"
            "3. Alternating Lunges: 3 sets x 10 reps each leg\n"
            "4. Plank Hold: 3 sets x 30-45 seconds\n"
            "5. Jumping Jacks: 45 seconds to burn calories!\n\n"
            "Rest 45 seconds between sets. Remember to warm up for 2 minutes before starting!";
      }

      if (q.contains('cardio') || q.contains('fat burn') || q.contains('weight loss')) {
        return "For effective fat burning and cardiovascular endurance:\n\n"
            "• Try a 25-minute Interval Session: 1 minute brisk jog/run followed by 1 minute moderate walk, repeated 10 times.\n"
            "• Add 5 minutes of cool-down stretching.\n"
            "• Maintaining an elevated heart rate burns calories while building stamina!";
      }

      if (q.contains('abs') || q.contains('core')) {
        return "Core Blast Routine (3 Rounds):\n\n"
            "• Forearm Plank: 45 seconds\n"
            "• Bicycle Crunches: 20 reps\n"
            "• Mountain Climbers: 30 seconds\n"
            "• Deadbugs: 12 reps per side\n\n"
            "Engage your core tight throughout and breathe rhythmically!";
      }

      return "Here is a balanced fitness routine recommendation:\n\n"
          "• Warm-up (3 mins): Arm circles, high knees, and hip rotations.\n"
          "• Strength (15 mins): 3 sets of Push-ups, Squats, and Glute Bridges.\n"
          "• Cardio Finish (5 mins): Mountain climbers or brisk jumping jacks.\n"
          "• Cool-down: Hamstring and chest stretches.\n\n"
          "Listen to your body and adjust intensity to your comfort level!";
    }

    // 4. Step Goal & Walking
    if (q.contains('step') || q.contains('walk') || q.contains('walking') || q.contains('10000')) {
      final remaining = (stepGoal - steps) > 0 ? stepGoal - steps : 0;
      return "Tips to crush your step goal ($stepGoal steps):\n\n"
          "1. Post-Meal Walk: A 10-minute stroll after lunch and dinner adds ~2,000 steps and lowers blood sugar.\n"
          "2. Walk & Talk: Take phone calls or virtual check-ins while pacing around.\n"
          "3. Take the Stairs: Ditch elevators for 2-3 floors.\n\n"
          "${remaining > 0 ? "You only need $remaining more steps today—let's get moving!" : "You have already reached your goal today! Superb job!"}";
    }

    // 5. Water & Hydration
    if (q.contains('water') || q.contains('hydration') || q.contains('drink') || q.contains('thirst')) {
      return "Hydration Guide:\n\n"
          "• Daily Target: Aim for 2.5 to 3.5 liters per day (logged: ${waterLiters.toStringAsFixed(1)}L today).\n"
          "• Tip 1: Start your morning with 500ml of water before your first coffee or tea.\n"
          "• Tip 2: Sip 200ml every 20 minutes during workouts.\n"
          "• Proper hydration prevents fatigue, relieves muscle cramps, and speeds recovery!";
    }

    // 6. Sleep & Recovery
    if (q.contains('sleep') ||
        q.contains('rest') ||
        q.contains('tired') ||
        q.contains('recovery') ||
        q.contains('sore') ||
        q.contains('insomnia') ||
        q.contains('bedtime')) {
      return "Sleep & Recovery Blueprint:\n\n"
          "• Target 7-9 hours of restful sleep for cellular repair and hormone balance.\n"
          "• Dim screens & blue light 60 minutes before bedtime.\n"
          "• Keep your bedroom cool (around 19-21°C) and completely dark.\n"
          "• If your muscles are sore, do 10 minutes of gentle yoga or foam rolling today.";
    }

    // 7. Weather-based guidance
    if (q.contains('weather') || q.contains('rain') || q.contains('hot') || q.contains('temperature')) {
      return "Weather Fitness Advice (Current: $weatherTemp):\n\n"
          "• If it's warm (>32°C): Exercise in the early morning or evening, stay in shaded areas, and drink electrolyte water.\n"
          "• If rainy or cold: Enjoy an indoor bodyweight circuit, jump rope, or mobility stretching in your living room!";
    }

    // 8. Motivation & Consistency
    if (q.contains('lazy') ||
        q.contains('motivat') ||
        q.contains('give up') ||
        q.contains('hard') ||
        q.contains('tired') ||
        q.contains('discipline')) {
      return "Listen to me, $name: Consistency beats intensity every single time.\n\n"
          "You don't need a grueling 2-hour workout today. Use the '5-Minute Rule': just put on your shoes and move for 5 minutes. If you still want to stop, you can. 90% of the time, momentum will carry you through!\n\n"
          "You've already got $steps steps logged. Believe in the process!";
    }

    // 9. Greetings & Welcome
    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('coach') || q == 'help') {
      return "Hey $name! 👋 I'm your LiveFit AI Coach. I'm here to help you achieve your goals.\n\n"
          "You can ask me anything like:\n"
          "• \"How am I doing on my steps today?\"\n"
          "• \"Suggest a 15-minute home workout\"\n"
          "• \"What should I eat after training?\"\n"
          "• \"Tips to improve deep sleep\"\n\n"
          "What would you like to work on right now?";
    }

    // 10. Default contextual answer
    return "Great question, $name! As your LiveFit coach, I recommend focusing on consistent daily habits: hitting your $stepGoal step target, drinking plenty of water (logged ${waterLiters.toStringAsFixed(1)}L today), and prioritizing balanced protein with each meal.\n\n"
        "Ask me for a specific workout routine, meal suggestion, or recovery tip whenever you're ready!";
  }
}
