import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

@lazySingleton
class AIService {
  static const _defaultApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _defaultModelName = 'gemini-1.5-flash'; // safer + stable

  final SettingsService _settingsService;
  late final GenerativeModel _model;

  AIService(this._settingsService) {
    _model = GenerativeModel(
      model: _defaultModelName,
      apiKey: _defaultApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // 🔥 reduce hallucination
      ),
    );
  }

  Future<Map<String, dynamic>?> analyzeReceiptImage(
      Uint8List imageBytes) async {
    const systemPrompt = '''
You are an expert OCR + financial parser.

Extract structured data from the image.

Return ONLY valid JSON (no markdown, no explanation).

Supported types:

1. Refuel:
{
"type": "refuel",
"name": "...",
"date": "YYYY-MM-DD",
"liter": number,
"price_per_liter": number,
"total_amount": number,
"currency": "...",
"odometer": number|null
}

2. Store:
{
"type": "store",
"name": "...",
"date": "YYYY-MM-DD",
"items": [{"name": "...", "qty": number, "price": number, "total": number}],
"total_amount": number,
"currency": "...",
"odometer": number|null
}

3. Mechanic:
{
"type": "mechanic",
"name": "...",
"date": "YYYY-MM-DD",
"items": [{"name": "...", "price": number}],
"labor_cost": number|null,
"total_amount": number,
"currency": "...",
"odometer": number|null
}

RULES:
- Extract odometer if visible (e.g. KM, mileage, odo)
- Do NOT guess values
- Numbers must be numeric (no currency symbols)
- If unclear → use null
''';

    if (_settingsService.aiBaseUrl.isNotEmpty) {
      return await _analyzeWithOpenAI(imageBytes, systemPrompt);
    }

    if (_defaultApiKey.isEmpty) {
      debugPrint('Missing GEMINI_API_KEY');
      return null;
    }

    try {
      final prompt = TextPart(systemPrompt);
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model
          .generateContent([Content.multi([prompt, imagePart])])
          .timeout(const Duration(seconds: 25));

      final text = response.text;
      if (text == null) return null;

      return _safeJsonParse(text);
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return null;
    }
  }

  /// 🔥 SAFE JSON PARSER (CRITICAL FIX)
  Map<String, dynamic>? _safeJsonParse(String raw) {
    try {
      String cleaned = raw.trim();

      // remove markdown
      if (cleaned.contains('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'```json'), '')
            .replaceAll('```', '')
            .trim();
      }

      return jsonDecode(cleaned);
    } catch (e) {
      debugPrint('JSON Parse Failed: $e');
      debugPrint('RAW RESPONSE: $raw');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeWithOpenAI(
      Uint8List imageBytes, String systemPrompt) async {
    final baseUrl = _settingsService.aiBaseUrl;
    final apiKey = _settingsService.aiApiKey;
    final model = _settingsService.aiModel;

    final url = Uri.parse(
        baseUrl.endsWith('/') ? '${baseUrl}chat/completions' : '$baseUrl/chat/completions');

    final base64Image = base64Encode(imageBytes);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'temperature': 0.2,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Extract receipt data'},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _safeJsonParse(content.toString());
      }
    } catch (e) {
      debugPrint('OpenAI Error: $e');
    }

    return null;
  }
}