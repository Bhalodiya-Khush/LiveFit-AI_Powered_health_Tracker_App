import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/gemini_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F3F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
          primary: const Color(0xFFF97316),
          secondary: const Color(0xFFFB923C),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF97316),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFE7D6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFE7D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (_isLoginMode) {
      if (email.isEmpty || password.isEmpty) {
        _showMessage('Please enter your email and password.');
        return;
      }
    } else {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _showMessage('Please complete all required fields.');
        return;
      }

      if (password != confirmPassword) {
        _showMessage('Passwords do not match.');
        return;
      }
    }

    final authService = AuthService();
    print('Attempting login for: $email');
    final result = _isLoginMode
        ? await authService.login(email: email, password: password)
        : await authService.createAccount(
            name: name,
            email: email,
            password: password,
          );

    print('Login Result: $result');

    if (!mounted) return;

    if (result == null) {
      _showMessage('Authentication failed. Please try again.');
      return;
    }

    _showMessage('Welcome to LiveFit!');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(user: result['user'] ?? {'name': name ?? 'Athlete'}),
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    final googleName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Google User';
    final googleEmail = _emailController.text.trim();

    if (googleEmail.isEmpty) {
      _showMessage('Please enter your Google email address.');
      return;
    }

    final authService = AuthService();
    final result = await authService.googleLogin(name: googleName, email: googleEmail);

    if (!mounted) return;

    if (result == null) {
      _showMessage('Google login failed.');
      return;
    }

    _showMessage('Google login successful.');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(user: result['user'] ?? {'name': googleName}),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoginMode = _isLoginMode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildBrandHeader(),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoginMode ? 'Welcome back' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoginMode
                          ? 'Log in to continue your health journey.'
                          : 'Start building a healthier lifestyle today.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isLoginMode) ...[
                      _buildField(
                        controller: _nameController,
                        hintText: 'Full name',
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(
                      controller: _emailController,
                      hintText: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    if (!isLoginMode) ...[
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm password',
                        icon: Icons.lock_reset_outlined,
                        isPassword: true,
                      ),
                    ],
                    if (isLoginMode) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showMessage('Password reset coming soon.'),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isLoginMode ? 'Login' : 'Create Account'),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _continueWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFF97316)),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          side: const BorderSide(color: Color(0xFFFFE7D6)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLoginMode ? 'Need an account?' : 'Already have an account?',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            isLoginMode ? 'Create account' : 'Login',
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'LF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'LiveFit',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2937),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFFF97316)),
      ),
    );
  }
}

class AuthService {
  // Use localhost for Web/Desktop/iOS Simulator
  // Use 10.0.2.2 for Android Emulator
  static const String baseUrl = 'http://localhost:5000/api'; 

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        print('Login failed: ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
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
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 201 && response.statusCode != 200) {
        print('Registration failed: ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> googleLogin({
    required String name,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Google login failed: ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
  }
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _steps = 8420;
  int _sleepMinutes = 0;
  late int _sleepGoalMinutes;
  late int _stepGoal;
  String _sleepTime = '00:00';
  String _wakeUpTime = '00:00';
  String _aiInsight = 'Loading your live health insight...';
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _stepGoal = widget.user['goals']?['stepGoal'] ?? 10000;
    _sleepGoalMinutes = widget.user['goals']?['sleepGoal'] ?? 480;
    _loadInsight();
    _loadSleepData();
  }

  Future<void> _loadInsight() async {
    final insight = await _geminiService.getHealthInsight(
      steps: _steps,
      sleepMinutes: _sleepMinutes,
      waterLiters: 2.1,
    );

    if (!mounted) return;

    setState(() {
      _aiInsight = insight;
    });
  }

  Future<void> _loadSleepData() async {
    setState(() {
      _sleepMinutes = 0;
      _sleepGoalMinutes = 420;
      _sleepTime = '00:00';
      _wakeUpTime = '00:00';
    });

    if (!mounted) return;

    final sleepSummary = {
      'sleepMinutes': 0,
      'sleepGoalMinutes': 420,
      'sleepTime': '00:00',
      'wakeUpTime': '00:00',
    };

    setState(() {
      _sleepMinutes = (sleepSummary['sleepMinutes'] as int?) ?? 0;
      _sleepGoalMinutes = widget.user['goals']?['sleepGoal'] ?? 480;
      _sleepTime = sleepSummary['sleepTime'] as String? ?? '00:00';
      _wakeUpTime = sleepSummary['wakeUpTime'] as String? ?? '00:00';
    });

    await _loadInsight();
  }

  void _updateSteps(int delta) {
    setState(() {
      _steps = (_steps + delta).clamp(0, 25000);
    });
    _loadInsight();
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / _stepGoal).clamp(0.0, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.notifications_none, color: Color(0xFF1F2937)),
                      SizedBox(width: 12),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFFFE7D6),
                        child: Icon(Icons.person, color: Color(0xFFF97316)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Fitness Tracking Device',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatPill(label: 'Statistics', active: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatPill(label: 'Shop', active: false),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              minimumSize: const Size(0, 42),
                            ),
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      width: 140,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE7D4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          'image with desc',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C2D12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StepTrackingScreen(
                        initialSteps: _steps,
                        onChanged: _updateSteps,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1C),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Step Count',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_steps',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/ $_stepGoal',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to open the step tracker',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bedtime_rounded, color: Color(0xFFF97316)),
                        SizedBox(width: 10),
                        Text(
                          'Sleep tracking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You slept ${_formatMinutes(_sleepMinutes)} last night. Your target is ${_formatMinutes(_sleepGoalMinutes)}.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sleep time: $_sleepTime   •   Wake-up: $_wakeUpTime',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFFF97316)),
                        SizedBox(width: 10),
                        Text(
                          'AI coach insight',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _aiInsight,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome back, ${widget.user['name']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Steps',
                      value: '$_steps',
                      accent: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Step Goal',
                      value: '$_stepGoal',
                      accent: const Color(0xFFFB923C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepTrackingScreen extends StatefulWidget {
  final int initialSteps;
  final void Function(int) onChanged;

  const StepTrackingScreen({
    super.key,
    required this.initialSteps,
    required this.onChanged,
  });

  @override
  State<StepTrackingScreen> createState() => _StepTrackingScreenState();
}

class _StepTrackingScreenState extends State<StepTrackingScreen> {
  late int _steps = widget.initialSteps;

  @override
  Widget build(BuildContext context) {
    final percent = (_steps / 10000).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Count'),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Daily steps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$_steps',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFFFE7D6),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_steps / 10000 * 100).toStringAsFixed(0)}% of goal',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _steps = (_steps - 500).clamp(0, 25000);
                      });
                    },
                    icon: const Icon(Icons.remove),
                    label: const Text('Minus 500'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _steps = (_steps + 500).clamp(0, 25000);
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add 500'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onChanged(_steps);
                  Navigator.of(context).pop();
                },
                child: const Text('Save steps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
