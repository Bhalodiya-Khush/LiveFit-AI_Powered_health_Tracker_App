import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _weatherApiKey = '75deb0417ba450a88cdb8fb43105980b';
  final String _geminiApiKey = 'gen-lang-client-0701528390';

  Future<Map<String, dynamic>> getWeatherRecommendation(String city) async {
    try {
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?units=metric&q=${Uri.encodeComponent(city)}&appid=$_weatherApiKey');

      final weatherRes = await http.get(weatherUrl);
      if (weatherRes.statusCode != 200) {
        return _getFallbackData(city, 'Weather service unavailable.');
      }

      final weatherData = jsonDecode(weatherRes.body);
      final double temp = (weatherData['main']['temp'] as num).toDouble();
      final String condition = weatherData['weather'][0]['main'];
      final String description = weatherData['weather'][0]['description'];

      bool isOutdoorSafe = true;
      if (temp > 35 || temp < 10 || ['Rain', 'Snow', 'Thunderstorm'].contains(condition)) {
        isOutdoorSafe = false;
      }

      String aiRecommendation = "It's currently $temp°C and $description in $city. ${
        isOutdoorSafe 
            ? 'Conditions are great for outdoor workouts like running or cycling.' 
            : 'We recommend staying indoors today. Try some yoga or light indoor strength training.'
      }";

      // Call Gemini directly from Dart
      try {
        final geminiUrl = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey');

        final prompt = '''
You are an expert AI fitness coach for the LiveFit app.
Current Weather in $city:
- Temperature: $temp°C
- Condition: $condition ($description)
- Outdoor Safe: ${isOutdoorSafe ? 'Yes' : 'No'}

Write a personalized, concise fitness recommendation (max 2 sentences) based on this weather. Suggest 2-3 specific activities suitable for this environment. Do not use markdown format.
''';

        final geminiRes = await http.post(
          geminiUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );

        if (geminiRes.statusCode == 200) {
          final geminiData = jsonDecode(geminiRes.body);
          final text = geminiData['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.trim().isNotEmpty) {
            aiRecommendation = text.trim();
          }
        }
      } catch (geminiErr) {
        debugPrint('Gemini weather service error: $geminiErr');
      }

      return {
        'city': city,
        'temp': '$temp°C',
        'description': description,
        'recommendation': aiRecommendation,
      };
    } catch (e) {
      debugPrint('WeatherService General Error: $e');
      return _getFallbackData(city, 'Error connecting to weather services.');
    }
  }

  Map<String, dynamic> _getFallbackData(String city, String message) {
    return {
      'city': city,
      'temp': '--°C',
      'description': 'Unknown',
      'recommendation': '$message Please choose a fallback indoor exercise routine like yoga or stretching.',
    };
  }
}
