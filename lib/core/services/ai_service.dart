import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'settings_service.dart';

class AIException implements Exception {
  final String message;
  final String? code;
  AIException(this.message, {this.code});
  @override
  String toString() => message;
}

enum ReceiptType { fuel, pos, mechanic, unknown }

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
        responseSchema: Schema.object(
          properties: {
            'type': Schema.enumString(enumValues: ['refuel', 'store', 'mechanic']),
            'name': Schema.string(nullable: true),
            'date': Schema.string(nullable: true),
            'total_amount': Schema.number(nullable: true),
            'currency': Schema.string(nullable: true),
            'odometer': Schema.number(nullable: true),
            'liter': Schema.number(nullable: true),
            'price_per_liter': Schema.number(nullable: true),
            'items': Schema.array(
              items: Schema.object(
                properties: {
                  'name': Schema.string(nullable: true),
                  'qty': Schema.number(nullable: true),
                  'price': Schema.number(nullable: true),
                  'total': Schema.number(nullable: true),
                },
              ),
              nullable: true,
            ),
          },
          requiredProperties: ['type'],
        ),
        temperature: 0.2, // 🔥 reduce hallucination
      ),
    );
  }

  Future<Map<String, dynamic>?> analyzeReceiptImage(
      Uint8List imageBytes, {ReceiptType? typeHint}) async {
    final typeStr = typeHint?.name ?? 'refuel';

    final systemPrompt = '''
You are an expert OCR + financial parser.

Extract structured data from the image.
The user has already identified this as a "$typeStr" receipt/bill.

Return ONLY valid JSON (no markdown, no explanation).

"type": MUST be exactly "$typeStr".

Fields to extract:
1. Refuel:
{
"type": "refuel",
"name": "Station Name",
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
"name": "Store Name",
"date": "YYYY-MM-DD",
"items": [{"name": "item name", "qty": number, "price": unit_price, "total": line_total}],
"total_amount": number,
"currency": "...",
"odometer": number|null
}

3. Mechanic:
{
"type": "mechanic",
"name": "Mechanic/Garage Name",
"date": "YYYY-MM-DD",
"items": [{"name": "Service/Part description", "price": cost}],
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
      throw AIException('Gemini API Key is not configured. Please add it to your environment.');
    }

    try {
      debugPrint('AI_SERVICE: Sending image to Gemini...');
      final prompt = TextPart(systemPrompt);
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model
          .generateContent([Content.multi([prompt, imagePart])])
          .timeout(const Duration(seconds: 25));

      final text = response.text;
      debugPrint('AI_SERVICE: Raw text from Gemini: "$text"');
      
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log('AI_SERVICE: Gemini RAW RESPONSE: $text');
      }

      if (text == null) {
        throw AIException('Gemini returned an empty response. The image might be too blurry or contain no readable text.');
      }

      final parsed = safeJsonParse(text);
      if (parsed == null) {
        debugPrint('AI_SERVICE Error: Failed to parse JSON from: "$text"');
        throw AIException('Failed to extract data from the receipt. The format might be unsupported.');
      }
      return parsed;
    } on GenerativeAIException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') || msg.contains('429')) {
        throw AIException('AI Rate limit exceeded. Please try again in a few minutes.', code: 'quota_exceeded');
      } else if (msg.contains('api key') || msg.contains('401') || msg.contains('403')) {
        throw AIException('Invalid Gemini API Key. Please check your configuration.', code: 'invalid_api_key');
      } else if (msg.contains('safety')) {
        throw AIException('The image was flagged by safety filters. Please ensure it is a valid receipt.', code: 'safety_filter');
      }
      throw AIException('Gemini AI Error: ${e.message}');
    } on UnsupportedError catch (e) {
      throw AIException('This device or platform does not support the AI model: ${e.message}');
    } catch (e) {
      if (e is AIException) rethrow;
      debugPrint('AI_SERVICE Gemini Error: $e');
      throw AIException('Unexpected AI error: ${e.toString()}');
    }
  }

  /// 🔥 ROBUST JSON EXTRACTOR
  @visibleForTesting
  Map<String, dynamic>? safeJsonParse(String raw) {
    try {
      String cleaned = raw.trim();

      // 1. Precise Markdown Extraction
      if (cleaned.contains('```')) {
        final regExp = RegExp(r'```(?:json)?([\s\S]*?)```');
        final match = regExp.firstMatch(cleaned);
        if (match != null) {
          cleaned = match.group(1)!.trim();
          debugPrint('AI_SERVICE: Extracted from markdown: "$cleaned"');
        }
      }

      // 2. Brute Force Substring Extraction (Find first { and last })
      if (!cleaned.startsWith('{')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          cleaned = cleaned.substring(start, end + 1);
          debugPrint('AI_SERVICE: Extracted via braces indexing: "$cleaned"');
        }
      }

      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        debugPrint('AI_SERVICE: Successfully parsed JSON. Type: ${decoded['type']}');
        return decoded;
      }
      debugPrint('AI_SERVICE Error: Parsed JSON is not a Map: $decoded');
      return null;
    } catch (e, stackTrace) {
      debugPrint('AI_SERVICE JSON Parse Failed: $e');
      debugPrint('AI_SERVICE RAW RESPONSE causing failure: "$raw"');
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.log('AI_SERVICE RAW RESPONSE causing failure: "$raw"');
        FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'AI JSON Parse Failed');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeWithOpenAI(
      Uint8List imageBytes, String systemPrompt) async {
    final baseUrl = _settingsService.aiBaseUrl;
    final apiKey = _settingsService.aiApiKey;
    final model = _settingsService.aiModel;

    if (apiKey.isEmpty) {
      throw AIException('Custom AI API Key is missing. Please check your settings.', code: 'missing_api_key');
    }

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
        return safeJsonParse(content.toString());
      } else {
        String errorMsg = 'AI API Error (Status ${response.statusCode})';
        String? code;

        try {
          final errData = jsonDecode(response.body);
          errorMsg = errData['error']?['message'] ?? errorMsg;
          code = errData['error']?['code'];
        } catch (_) {}

        if (response.statusCode == 401) {
          throw AIException('Invalid AI API Key. Please verify your credentials.', code: 'invalid_api_key');
        } else if (response.statusCode == 404) {
          throw AIException('AI API Endpoint not found. Please check the Base URL.', code: 'invalid_url');
        } else if (response.statusCode == 429) {
          throw AIException('AI Rate limit exceeded. Please try again later.', code: 'quota_exceeded');
        } else if (response.statusCode >= 500) {
          throw AIException('AI Provider is currently unavailable. Please try again in a moment.', code: 'provider_down');
        }
        
        throw AIException(errorMsg, code: code);
      }
    } catch (e, stackTrace) {
      if (e is AIException) rethrow;
      debugPrint('OpenAI Error: $e');
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'OpenAI API Request Failed');
      }
      throw AIException('Connection failed: Could not reach the AI service. Please check your internet.');
    }
  }
}