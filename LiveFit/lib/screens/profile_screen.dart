import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  final VoidCallback? onConfigureApiKey;
  final void Function(int newStepGoal, int newSleepGoal)? onGoalsUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.onConfigureApiKey,
    this.onGoalsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _heightCm = 175;
  double _currentWeightKg = 68;
  double _targetWeightKg = 68;
  late int _stepGoal;
  late int _sleepGoalMinutes;

  @override
  void initState() {
    super.initState();
    _heightCm = (widget.user['height'] as num?)?.toDouble() ?? 175;
    _currentWeightKg = (widget.user['weight'] as num?)?.toDouble() ?? 68;
    _targetWeightKg = _currentWeightKg;
    _stepGoal = (widget.user['goals']?['stepGoal'] as num?)?.toInt() ?? 10000;
    _sleepGoalMinutes = (widget.user['goals']?['sleepGoal'] as num?)?.toInt() ?? 480;
  }

  double get _bmi {
    final heightM = _heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return _currentWeightKg / (heightM * heightM);
  }

  String get _bmiCategory {
    final val = _bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Normal weight';
    if (val < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    final val = _bmi;
    if (val < 18.5) return Colors.blue;
    if (val < 25.0) return const Color(0xFF10B981);
    if (val < 30.0) return Colors.orange;
    return Colors.red;
  }

  void _showEditBiometricsDialog() {
    final heightController = TextEditingController(text: _heightCm.toInt().toString());
    final weightController = TextEditingController(text: _currentWeightKg.toInt().toString());
    final targetWeightController = TextEditingController(text: _targetWeightKg.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Update Biometric Stats', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (cm)', suffixText: 'cm'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current Weight (kg)', suffixText: 'kg'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Weight (kg)', suffixText: 'kg'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newHeight = double.tryParse(heightController.text) ?? _heightCm;
              final newWeight = double.tryParse(weightController.text) ?? _currentWeightKg;
              final newTarget = double.tryParse(targetWeightController.text) ?? _targetWeightKg;
              setState(() {
                _heightCm = newHeight;
                _currentWeightKg = newWeight;
                _targetWeightKg = newTarget;
              });
              await ApiService().updateProfile(height: newHeight, weight: newWeight);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalsDialog() {
    final stepController = TextEditingController(text: _stepGoal.toString());
    final sleepController = TextEditingController(text: (_sleepGoalMinutes ~/ 60).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Customize Daily Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Step Target', suffixText: 'steps'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sleepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Sleep Target (hours)', suffixText: 'hours'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStep = int.tryParse(stepController.text) ?? _stepGoal;
              final newSleep = (int.tryParse(sleepController.text) ?? 8) * 60;
              setState(() {
                _stepGoal = newStep;
                _sleepGoalMinutes = newSleep;
              });
              widget.onGoalsUpdated?.call(newStep, newSleep);
              await ApiService().updateProfile(
                goals: UserGoals(stepGoal: newStep, sleepGoal: newSleep),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
            child: const Text('Apply Goals'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['name'] ?? 'Alex Johnson';
    final userEmail = widget.user['email'] ?? 'alex.fitness@example.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F2),
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
                    child: const Icon(Icons.person, size: 36, color: Color(0xFFF97316)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        const SizedBox(height: 2),
                        Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LiveFit Premium Active',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B7280)),
                    tooltip: 'Edit Profile',
                    onPressed: () {
                      showRemainingFeatureDialog(
                        context,
                        title: 'Edit Profile & Avatar',
                        details: 'User avatar upload and personal bio editing will connect to user microservice in Phase 2.',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Biometric Stats & BMI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biometrics & Body Mass Index', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFFF97316)),
                        onPressed: _showEditBiometricsDialog,
                        tooltip: 'Edit Biometrics',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBiometricTile('${_heightCm.toInt()} cm', 'Height'),
                      _buildBiometricTile('${_currentWeightKg.toInt()} kg', 'Weight'),
                      _buildBiometricTile('${_targetWeightKg.toInt()} kg', 'Target'),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Body Mass Index (BMI)', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(_bmi.toStringAsFixed(1), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _bmiColor)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _bmiColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_bmiCategory, style: TextStyle(color: _bmiColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const StatusBadge.live(label: 'Calculated'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Daily Targets
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Personal Daily Goals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFF97316)),
                        onPressed: _showEditGoalsDialog,
                        tooltip: 'Customize Goals',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildGoalRow(Icons.directions_walk, 'Step Goal', '$_stepGoal steps/day'),
                  _buildGoalRow(Icons.bedtime, 'Sleep Target', '${_sleepGoalMinutes ~/ 60} hours/night'),
                  _buildGoalRow(Icons.local_fire_department, 'Calorie Intake', '2,200 kcal/day'),
                  _buildGoalRow(Icons.water_drop, 'Hydration Target', '3.0 Liters/day'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Connected Hardware & Devices Hub
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connected Hardware & Devices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _buildDeviceRow(
                    Icons.smartphone_rounded,
                    'Mobile Phone Hardware Pedometer',
                    'Internal Accelerometer Sensor',
                    const StatusBadge.live(label: 'Connected'),
                  ),
                  const Divider(height: 18),
                  _buildDeviceRow(
                    Icons.watch_rounded,
                    'Smartwatch & BLE Continuous HR',
                    'Bluetooth Low Energy',
                    const StatusBadge.remaining(
                      label: 'Remaining (Phase 2)',
                      featureName: 'Bluetooth Smartwatch HR Sync',
                      description: 'Direct BLE pairing with Garmin, Apple Watch, and Wear OS devices is scheduled for Phase 2.',
                    ),
                  ),
                  const Divider(height: 18),
                  _buildDeviceRow(
                    Icons.cloud_sync_rounded,
                    'Apple Health / Google Health Connect',
                    'Bi-directional Cloud Health Sync',
                    const StatusBadge.remaining(
                      label: 'Remaining (Phase 2)',
                      featureName: 'HealthKit & Health Connect Sync',
                      description: 'Integration with system health hubs is queued for the native mobile release.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // App Settings & Actions
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                  ListTile(
                    leading: const Icon(Icons.vpn_key_outlined, color: Color(0xFFF97316)),
                    title: const Text('Gemini AI Coach Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Configure custom Google Gemini API Key', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onConfigureApiKey,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined, color: Color(0xFF6B7280)),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const StatusBadge.remaining(label: 'Remaining'),
                    onTap: () {
                      showRemainingFeatureDialog(
                        context,
                        title: 'Password Security Settings',
                        details: 'Account credential updates and 2FA authentication will be enabled once the backend auth vault is updated.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    title: const Text('Log Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    onTap: widget.onLogout,
                  ),
                ],
              ),
            ),
          ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricTile(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildGoalRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(IconData icon, String name, String subtitle, Widget badge) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF374151)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        badge,
      ],
    );
  }
}
