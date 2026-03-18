import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

@lazySingleton
class AIService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _modelName = 'gemini-2.5-flash-preview-09-2025';

  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  /// NEW NATIVE IMAGE FLOW (Modeled exactly after user's index.js)
  Future<Map<String, dynamic>?> analyzeReceiptImage(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      debugPrint('WARNING: GEMINI_API_KEY is not set. AI parsing will not work.');
      return null;
    }

    const systemPrompt = '''
You are an expert OCR agent. Extract data from the receipt image into one of these 3 JSON formats:

1. If Refuel (Gas/Petrol/Diesel): { "type": "refuel", "name": "Station Name", "date": "YYYY-MM-DD", "liter": 0.00, "total_amount": 0.00, "currency": "..." }
2. If Store (Groceries/Items): { "type": "store", "name": "Store Name", "date": "YYYY-MM-DD", "items": [{"name": "item", "qty": 1, "price": 0, "total": 0}], "total_amount": 0, "currency": "..." }
3. If Mechanic (Repairs/Parts/Labor): { "type": "mechanic", "name": "Shop Name", "date": "YYYY-MM-DD", "items": [{"name": "maintenance item", "price": 0}], "total_amount": 0, "currency": "..." }

CRITICAL: 
- If you see "Labor", "Service", "Repair", "Oil Filter", or "Brake Pad", classify as "mechanic".
- If you see "Super", "HSD", "Diesel", "Petrol" or specific liter counts, classify as "refuel".
- Return ONLY valid JSON.
''';

    try {
      final prompt = TextPart("Extract receipt data accurately.\n\n$systemPrompt");
      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final content = [Content.multi([prompt, imagePart])];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        return jsonDecode(response.text!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error during AI receipt image analysis: $e');
    }
    return null;
  }

  /// LEGACY TEXT FLOW (Retained for arbitrary text fallback if needed)
  Future<Map<String, dynamic>?> analyzeReceiptText(String text, String receiptType) async {
    if (_apiKey.isEmpty) {
      debugPrint('WARNING: GEMINI_API_KEY is not set. AI parsing will not work.');
      return null;
    }

    final prompt = _getPromptForType(receiptType, text);

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        return jsonDecode(response.text!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error during AI receipt analysis: $e');
    }
    return null;
  }

  String _getPromptForType(String type, String text) {
    switch (type) {
      case 'fuel':
        return '''
        Analyze the following text from a fuel/gas station receipt and extract the data into a JSON object.
        CRITICAL RULES:
        1. Do NOT confuse receipt numbers, transaction IDs, phone numbers, or zip codes with amounts or liters.
        2. "totalAmount" must be the final price paid. Look for keywords like "TOTAL", "AMOUNT", "NET AMO", "PAYMENT" next to currency symbols (Rs, PKR, \$, ¥).
        3. "liters" must be the volume of fuel pumped. Look for keywords like "LTR", "VOLUME", "QTY", "LITERS".
        4. "pricePerLiter" is the unit rate. Look for keywords like "RATE", "PRICE/L".
        5. Provide numbers as floats without currency symbols.
        
        JSON format:
        {
          "stationName": "string or null",
          "totalAmount": number or null,
          "liters": number or null,
          "pricePerLiter": number or null,
          "location": "string or null"
        }
        Text:
        \$text
        ''';
      case 'store':
        return '''
        Analyze the following text from a store/POS auto parts receipt and extract the data into a JSON object.
        CRITICAL RULES:
        1. Do NOT confuse receipt numbers (e.g. "No. 6438"), phone numbers, or dates with prices.
        2. "totalAmount" is the final total at the bottom.
        3. For "items", only include actual products or services sold, ignoring headers like "DESCRIPTION", "QTY", "AMOUNT", or footer messages.
        4. Provide numbers as floats without currency symbols.
        
        JSON format:
        {
          "storeName": "string or null",
          "items": [
            {
              "name": "string",
              "quantity": number,
              "price": number
            }
          ],
          "totalAmount": number or null
        }
        Text:
        \$text
        ''';
      case 'mechanic':
        return '''
        Analyze the following text from a mechanic or vehicle repair bill and extract the data into a JSON object.
        CRITICAL RULES:
        1. Do NOT confuse invoice numbers, phone numbers, or dates with prices.
        2. "totalAmount" is the sum or final price at the bottom.
        3. For "services", only include the labor or parts listed with a cost, ignoring headers or footer text.
        4. Provide numbers as floats without currency symbols.
        
        JSON format:
        {
          "mechanicName": "string or null",
          "services": [
            {
              "description": "string",
              "cost": number
            }
          ],
          "totalAmount": number or null
        }
        Text:
        \$text
        ''';
      default:
        return 'Analyze this text and extract any meaningful receipt data into JSON: \$text';
    }
  }
}
