import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:carlog/core/services/receipt_parser_service.dart';
import 'package:carlog/core/services/ai_service.dart';

class FakeAIService implements AIService {
  Map<String, dynamic>? currentResponse;

  @override
  Future<Map<String, dynamic>?> analyzeReceiptImage(Uint8List imageBytes) async {
    return currentResponse;
  }
  
  @override
  Future<Map<String, dynamic>?> analyzeReceiptText(String text, String type) async {
    return null;
  }
}

void main() {
  late ReceiptParserService service;
  late FakeAIService fakeAiService;
  late File dummyImage;

  setUpAll(() async {
    // We create a tiny dummy file to satisfy File().readAsBytes()
    dummyImage = File('dummy_receipt.jpg');
    await dummyImage.writeAsBytes(Uint8List.fromList([0, 1, 2]));
  });

  tearDownAll(() async {
    if (await dummyImage.exists()) {
      await dummyImage.delete();
    }
  });

  setUp(() {
    fakeAiService = FakeAIService();
    service = ReceiptParserService(fakeAiService);
  });

  group('Fuel Receipt Parsing', () {
    test('AI parsing strictly maps to ParsedFuelReceipt', () async {
      fakeAiService.currentResponse = {
        'type': 'refuel',
        'name': 'AI Station',
        'total_amount': 5000.0,
        'liter': 20.0,
      };

      final result = await service.parseFuelReceipt(dummyImage.path);
      expect(result.stationName, 'AI Station');
      expect(result.totalAmount, 5000.0);
      expect(result.liters, 20.0);
    });
  });

  group('POS Receipt Parsing', () {
    test('extracts items via AI', () async {
      fakeAiService.currentResponse = {
        'type': 'store',
        'name': 'Store Receipt',
        'items': [
          {'name': 'Oil Filter', 'qty': 1, 'price': 350.0},
          {'name': 'Air Filter', 'qty': 1, 'price': 250.0},
        ],
        'total_amount': 600.0,
      };

      final result = await service.parsePOSReceipt(dummyImage.path);
      expect(result.items.length, 2);
      expect(result.items[0].name, 'Oil Filter');
      expect(result.totalAmount, 600.0);
    });
  });

  group('Mechanic Bill Parsing', () {
    test('extracts services via AI', () async {
      fakeAiService.currentResponse = {
        'type': 'mechanic',
        'name': 'Mechanic Bill',
        'items': [
          {'name': 'Oil Change', 'price': 800.0},
        ],
        'total_amount': 800.0,
      };

      final result = await service.parseMechanicBill(dummyImage.path);
      expect(result.services.length, 1);
      expect(result.services[0].description, 'Oil Change');
      expect(result.totalAmount, 800.0);
    });
  });

  group('Master parseAnyReceipt', () {
    test('routes accurately based on type', () async {
      fakeAiService.currentResponse = {
        'type': 'refuel',
        'name': 'Master AI Station',
        'total_amount': 1000.0,
        'liter': 5.0,
      };

      final result = await service.parseAnyReceipt(dummyImage.path);
      expect(result, isA<ParsedFuelReceipt>());
      expect((result as ParsedFuelReceipt).stationName, 'Master AI Station');
    });
  });
}
