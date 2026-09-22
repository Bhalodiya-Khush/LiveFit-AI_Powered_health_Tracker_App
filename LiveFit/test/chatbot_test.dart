import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livefit/main.dart';
import 'package:livefit/services/gemini_service.dart';

void main() {
  group('GeminiService Chatbot Tests', () {
    late GeminiService geminiService;

    setUp(() {
      geminiService = GeminiService();
    });

    test('Chatbot responds to workout inquiries with exercise circuit', () async {
      final response = await geminiService.sendChatMessage(
        message: 'Suggest a quick home workout',
        userContext: {'name': 'Alex', 'steps': 5000, 'stepGoal': 10000},
      );

      expect(response.isNotEmpty, isTrue);
      expect(response.toLowerCase(), contains('squat'));
      expect(response.toLowerCase(), contains('push-up'));
    });

    test('Chatbot provides live personalized status based on user stats', () async {
      final response = await geminiService.sendChatMessage(
        message: 'How am I doing today?',
        userContext: {
          'name': 'Alex',
          'steps': 8420,
          'stepGoal': 10000,
          'sleepMinutes': 450,
          'waterLiters': 2.1,
        },
      );

      expect(response, contains('Alex'));
      expect(response, contains('8420'));
      expect(response, contains('10000'));
      expect(response, contains('1580 steps left'));
    });

    test('Chatbot responds to diet and protein questions', () async {
      final response = await geminiService.sendChatMessage(
        message: 'What should I eat after workout?',
      );

      expect(response.toLowerCase(), contains('protein'));
      expect(response.isNotEmpty, isTrue);
    });

    test('Chatbot responds to sleep and recovery questions', () async {
      final response = await geminiService.sendChatMessage(
        message: 'Tips for better sleep',
      );

      expect(response.toLowerCase(), contains('sleep'));
      expect(response.toLowerCase(), contains('dark'));
    });

    test('Chatbot handles API key state properly', () async {
      expect(geminiService.hasValidApiKey, isFalse);
      await geminiService.setCustomApiKey('AIzaSyDummyValidLookingKeyForTesting12345');
      expect(geminiService.hasValidApiKey, isTrue);
      expect(geminiService.currentApiKey, 'AIzaSyDummyValidLookingKeyForTesting12345');
      await geminiService.setCustomApiKey('');
      expect(geminiService.hasValidApiKey, isFalse);
    });
  });

  group('Chatbot UI Widget Tests', () {
    testWidgets('Dashboard renders chat card, suggestions and sends chat message', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            user: {
              'name': 'TestAthlete',
              'goals': {'stepGoal': 10000, 'sleepGoal': 480},
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Chat Card Header and Status
      expect(find.text('AI Coach Assistant Chat'), findsOneWidget);
      expect(find.text('Smart Coach Active'), findsOneWidget);

      // Verify Initial AI Welcome Message
      expect(find.textContaining('Hello TestAthlete!'), findsOneWidget);

      // Verify Quick Suggestion Chips exist
      final workoutChip = find.text('15-min Workout 🏋️');
      expect(workoutChip, findsOneWidget);
      expect(find.text('How am I doing? 📊'), findsOneWidget);

      await tester.ensureVisible(workoutChip);
      await tester.pumpAndSettle();

      // Tap on a suggestion chip
      await tester.tap(workoutChip);
      await tester.pumpAndSettle();

      // Verify that user message was added to chat history
      expect(find.text('15-min Workout 🏋️'), findsWidgets);

      // Verify that Coach responded with workout circuit
      expect(find.textContaining('Squats'), findsOneWidget);
    });

    testWidgets('AICoachChatScreen opens in full screen with stats and input', (WidgetTester tester) async {
      final geminiService = GeminiService();
      final chatHistory = <Map<String, String>>[
        {'role': 'ai', 'text': 'Welcome to your full-screen coach!'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AICoachChatScreen(
            geminiService: geminiService,
            chatHistory: chatHistory,
            userContext: {
              'name': 'Runner',
              'steps': 9000,
              'stepGoal': 10000,
              'sleepMinutes': 420,
              'weatherTemp': '24°C',
            },
            onSendMessage: (_) {},
            onClearChat: () {},
            onOpenSettings: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LiveFit AI Coach'), findsOneWidget);
      expect(find.text('Welcome to your full-screen coach!'), findsOneWidget);
      expect(find.textContaining('9000 / 10000 steps'), findsOneWidget);

      // Enter a question in the text field
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, 'Suggest a healthy snack');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.text('Suggest a healthy snack'), findsOneWidget);
      expect(find.textContaining('protein'), findsWidgets);
    });
  });
}
