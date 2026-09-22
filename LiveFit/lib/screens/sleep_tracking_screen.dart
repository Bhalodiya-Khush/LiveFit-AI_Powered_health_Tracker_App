import 'package:flutter/material.dart';

import '../services/sleep_service.dart';

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
    this.initialSleepTime = '23:30',
    this.initialWakeUpTime = '07:00',
    this.onSleepUpdated,
  });

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  late bool _isSleeping;
  late int _minutes;
  late String _sleepTime;
  late String _wakeTime;

  @override
  void initState() {
    super.initState();
    _isSleeping = widget.sleepService.isSleeping;
    _minutes = widget.initialMinutes;
    _sleepTime = widget.initialSleepTime;
    _wakeTime = widget.initialWakeUpTime;
  }

  Future<void> _handleToggle() async {
    if (_isSleeping) {
      final rec = await widget.sleepService.wakeUp();
      setState(() {
        _isSleeping = false;
        _minutes = rec.sleepMinutes;
        _wakeTime = rec.wakeUpTime;
      });
      widget.onSleepUpdated?.call(rec);
    } else {
      await widget.sleepService.startSleep();
      setState(() {
        _isSleeping = true;
        _sleepTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _minutes ~/ 60;
    final mins = _minutes % 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sleep Tracking & Analytics'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    _isSleeping ? Icons.nightlight_round : Icons.bedtime_rounded,
                    size: 64,
                    color: _isSleeping ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isSleeping ? 'SLEEP SESSION IN PROGRESS' : 'Track Overnight Rest',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${hours}h ${mins}m',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Bedtime: $_sleepTime → Wake: $_wakeTime',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _handleToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSleeping ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_isSleeping ? Icons.wb_sunny_rounded : Icons.bedtime_rounded),
                      label: Text(
                        _isSleeping ? 'Wake Up & Save Sleep ☀️' : 'Start Sleep Session 🌙',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4F46E5)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Getting 7-8 hours of sound sleep optimizes recovery, mental clarity, and metabolic function.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3730A3)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
