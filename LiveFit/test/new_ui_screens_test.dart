import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livefit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Single Main Page Architecture & Health Sections Tests', () {
    testWidgets('Dashboard renders all 9 required sections on one main page without heart beat', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            user: {
              'name': 'Alex',
              'email': 'alex@example.com',
              'age': 22,
              'weight': 70.0,
              'goals': {'stepGoal': 10000, 'sleepGoal': 480},
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Section 1: Daily Health Score
      expect(find.text('1. Daily Health Score'), findsOneWidget);

      // Section 2: Step Count
      expect(find.text('2. Step Count & Walking'), findsOneWidget);

      // Section 3: Sleep Tracking
      expect(find.text('3. Sleep Tracking'), findsOneWidget);

      // Section 4: Calories
      expect(find.text('4. Calories (kcal)'), findsOneWidget);

      // Section 5: Workouts tailored to age/weight/weather
      expect(find.text('5. Recommended Workouts for You'), findsOneWidget);

      // Section 6: Nutrition & Meal Calculator
      expect(find.text('6. Nutrition & Meal Calculator'), findsOneWidget);

      // Section 7: Weather Intelligence
      expect(find.text('7. Weather Intelligence'), findsOneWidget);

      // Section 8: AI Suggestions
      expect(find.text('8. AI Suggestions'), findsOneWidget);

      // Section 9: AI Coach Assistant Chat
      expect(find.text('9. AI Coach Assistant Chat'), findsOneWidget);

      // Confirm heart beat / pulse rate is removed from main page as requested
      expect(find.text('Resting Heart Rate'), findsNothing);
      expect(find.text('Heart Rate'), findsNothing);
    });

    testWidgets('Nutrition section calculates calories from food database and updates calories card', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            user: {
              'name': 'Alex',
              'age': 22,
              'weight': 70.0,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Food Database calculation function directly
      final testCal = FoodDatabase.calculateCalories('2 eggs, toast, tea');
      expect(testCal, greaterThan(200));

      // Check calculate button exists
      final calcBtn = find.text('Calculate Calories & Update Dashboard');
      expect(calcBtn, findsOneWidget);

      await tester.ensureVisible(calcBtn);
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Nutrition Updated!'), findsOneWidget);
    });

    testWidgets('Workout recommendation can be logged as Done to increase burned calories', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            user: {
              'name': 'Alex',
              'age': 22,
              'weight': 70.0,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find first "Done" workout button
      final doneButtons = find.text('Done');
      expect(doneButtons, findsWidgets);

      await tester.ensureVisible(doneButtons.first);
      await tester.tap(doneButtons.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Awesome! Completed'), findsOneWidget);
    });

    testWidgets('Profile button in AppBar navigates to ProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            user: {
              'name': 'Alex',
              'email': 'alex@example.com',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileIcon = find.byIcon(Icons.account_circle_rounded);
      expect(profileIcon, findsOneWidget);

      await tester.tap(profileIcon);
      await tester.pumpAndSettle();

      expect(find.text('Biometrics & Body Mass Index'), findsOneWidget);
    });
  });
}
