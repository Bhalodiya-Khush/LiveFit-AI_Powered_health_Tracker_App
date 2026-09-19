import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService({String? apiKey}) : _apiKey = apiKey ?? const String.fromEnvironment(
          'GEMINI_API_KEY',
          defaultValue: 'gen-lang-client-0701528390',
        );

  final String _apiKey;

  Future<String> getHealthInsight({
    required int steps,
    required int sleepMinutes,
    required double waterLiters,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );

    final prompt = '''
You are a friendly health coach for a fitness app called LiveFit.
User stats:
- Steps today: $steps
- Sleep: ${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m
- Water: ${waterLiters.toStringAsFixed(1)} L

Give a short motivational health update in 2 sentences. Recommend one action to improve their health today.
''';

    try {
      final response = await http.post(
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
      );

      if (response.statusCode != 200) {
        return 'AI insight unavailable right now. Keep moving and stay hydrated.';
      }

      final decoded = jsonDecode(response.body);
      final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
    } catch (_) {
      return 'AI insight unavailable right now. Keep moving and stay hydrated.';
    }

    return 'You are doing well. Aim for a brisk walk and keep your hydration consistent today.';
  }
}
