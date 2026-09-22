import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livefit/main.dart';
import 'package:livefit/services/sleep_service.dart';
import 'package:livefit/services/step_sensor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SleepService Unit Tests', () {
    late SleepService sleepService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sleepService = SleepService();
      await sleepService.initialize(defaultGoalMinutes: 480);
    });

    test('Initializes with default sleep stats when fresh', () {
      expect(sleepService.sleepGoalMinutes, 480);
      expect(sleepService.isSleeping, isFalse);
      expect(sleepService.history.length, 7);
    });

    test('startSleep sets isSleeping to true and records start time', () async {
      await sleepService.startSleep();

      expect(sleepService.isSleeping, isTrue);
      expect(sleepService.sleepStartTime, isNotNull);
    });

    test('wakeUp ends sleep session and records duration', () async {
      await sleepService.startSleep();
      expect(sleepService.isSleeping, isTrue);

      final record = await sleepService.wakeUp();

      expect(sleepService.isSleeping, isFalse);
      expect(sleepService.sleepStartTime, isNull);
      expect(record.sleepMinutes, greaterThanOrEqualTo(0));
      expect(sleepService.history.last.date, record.date);
    });

    test('logSleepManually logs custom sleep duration and updates history', () async {
      await sleepService.logSleepManually(
        minutes: 420,
        sleepTime: '23:15',
        wakeUpTime: '06:15',
      );

      expect(sleepService.sleepMinutes, 420);
      expect(sleepService.sleepTime, '23:15');
      expect(sleepService.wakeUpTime, '06:15');
      expect(sleepService.history.last.sleepMinutes, 420);
    });

    test('updateSleepGoal updates target minutes', () async {
      await sleepService.updateSleepGoal(510);
      expect(sleepService.sleepGoalMinutes, 510);
    });

    test('Session recovery resumes active sleep when app reopens', () async {
      final now = DateTime.now().subtract(const Duration(hours: 3));
      SharedPreferences.setMockInitialValues({
        'livefit_is_sleeping': true,
        'livefit_sleep_start_time': now.toIso8601String(),
      });

      final freshService = SleepService();
      await freshService.initialize();

      expect(freshService.isSleeping, isTrue);
      expect(freshService.getElapsedSleepMinutes(), greaterThanOrEqualTo(170));
    });
  });

  group('StepSensorService Unit Tests', () {
    late StepSensorService stepService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'livefit_today_steps': 3200,
        'livefit_pedometer_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      });
      stepService = StepSensorService();
      await stepService.initialize();
    });

    test('Loads stored daily steps on initialization', () {
      expect(stepService.currentDailySteps, 3200);
    });

    test('setStepsManually updates current daily steps and broadcasts update', () async {
      int? broadcasted;
      final sub = stepService.stepStream.listen((val) => broadcasted = val);

      await stepService.setStepsManually(5400);
      await Future<void>.delayed(Duration.zero);

      expect(stepService.currentDailySteps, 5400);
      expect(broadcasted, 5400);

      await sub.cancel();
    });
  });

  group('StepTrackingScreen & SleepTrackingScreen Widget Tests', () {
    late SleepService sleepService;
    late StepSensorService stepService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sleepService = SleepService();
      await sleepService.initialize();
      stepService = StepSensorService();
      await stepService.initialize();
    });

    testWidgets('StepTrackingScreen renders correctly and allows step adjustments', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int savedSteps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StepTrackingScreen(
            initialSteps: 6000,
            goalSteps: 10000,
            stepSensorService: stepService,
            onChanged: (steps) => savedSteps = steps,
          ),
        ),
      );

      expect(find.text('Real-Time Step Tracker'), findsOneWidget);
      expect(find.text('6000'), findsOneWidget);
      expect(find.text('Goal: 10000 steps'), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);

      // Tap +500
      await tester.ensureVisible(find.text('+500'));
      await tester.tap(find.text('+500'));
      await tester.pumpAndSettle();

      expect(find.text('6500'), findsOneWidget);

      // Tap Save
      await tester.ensureVisible(find.text('Save & Apply Steps'));
      await tester.tap(find.text('Save & Apply Steps'));
      await tester.pumpAndSettle();

      expect(savedSteps, 6500);
    });

    testWidgets('SleepTrackingScreen renders overview and supports Start Sleep', (tester) async {
      SleepRecord? updatedRecord;

      await tester.pumpWidget(
        MaterialApp(
          home: SleepTrackingScreen(
            sleepService: sleepService,
            initialMinutes: 450,
            initialGoalMinutes: 480,
            initialSleepTime: '23:00',
            initialWakeUpTime: '06:30',
            onSleepUpdated: (record) => updatedRecord = record,
          ),
        ),
      );

      expect(find.text('Sleep Tracking & Analytics'), findsOneWidget);
      expect(find.text('Track Overnight Rest'), findsOneWidget);
      expect(find.text('7h 30m'), findsOneWidget);
      expect(find.text('Start Sleep Session 🌙'), findsOneWidget);

      // Start sleep
      await tester.tap(find.text('Start Sleep Session 🌙'));
      await tester.pump();

      expect(find.text('SLEEP SESSION IN PROGRESS'), findsOneWidget);
      expect(find.text('Wake Up & Save Sleep ☀️'), findsOneWidget);

      // Wake up
      await tester.tap(find.text('Wake Up & Save Sleep ☀️'));
      await tester.pump();

      expect(updatedRecord, isNotNull);
      expect(find.text('Track Overnight Rest'), findsOneWidget);
    });
  });
}
