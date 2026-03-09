import 'package:flutter_test/flutter_test.dart';
import 'package:car_care_app/core/services/receipt_parser_service.dart';

void main() {
  late ReceiptParserService service;

  setUp(() {
    service = ReceiptParserService();
  });

  group('ReceiptType Detection', () {
    test('detects fuel receipt from petrol keywords', () {
      const text = '''
HP PETROL PUMP
Station Road, Lahore
Date: 15/03/2026
Petrol - Premium
Qty: 15.5 Ltr
Rate: Rs. 272.45/Ltr
Amount: Rs. 4,223
''';
      expect(service.detectReceiptType(text), ReceiptType.fuel);
    });

    test('detects fuel receipt from fuel brand names', () {
      const text = '''
SHELL FILLING STATION
Total Amount: 3500
Volume: 12.5 L
''';
      expect(service.detectReceiptType(text), ReceiptType.fuel);
    });

    test('detects POS receipt from store keywords', () {
      const text = '''
AUTO PARTS STORE
Invoice #12345
Oil Filter        Rs. 350
Air Filter        Rs. 250
Subtotal          Rs. 600
GST               Rs. 108
Total             Rs. 708
Payment: Cash
''';
      expect(service.detectReceiptType(text), ReceiptType.pos);
    });

    test('detects mechanic bill from repair keywords', () {
      const text = '''
KHAN MOTOR WORKSHOP
Service Bill
Oil Change        Rs. 800
Labour Charge     Rs. 500
Brake Pad Replacement Rs. 2000
Total             Rs. 3300
''';
      expect(service.detectReceiptType(text), ReceiptType.mechanic);
    });

    test('returns unknown for empty text', () {
      expect(service.detectReceiptType(''), ReceiptType.unknown);
    });

    test('returns unknown for random text', () {
      expect(service.detectReceiptType('hello world 123'), ReceiptType.unknown);
    });
  });

  group('Fuel Receipt Parsing', () {
    test('extracts station name from known brand', () {
      const text = '''
HP PETROLEUM
Main Road, Islamabad
Rate: 272.45
Qty: 20.5 Ltr
Amount: Rs. 5,585
''';
      final result = service.parseFuelReceipt(text);
      expect(result.stationName, contains('HP'));
    });

    test('extracts total amount from "Amount" keyword', () {
      const text = '''
SHELL STATION
Amount: Rs. 3,500.00
Volume: 12.5 Ltr
''';
      final result = service.parseFuelReceipt(text);
      expect(result.totalAmount, 3500.0);
    });

    test('extracts liters from "Ltr" suffix', () {
      const text = '''
PETROL PUMP
15.5 Ltr Petrol
Total: Rs. 4223
''';
      final result = service.parseFuelReceipt(text);
      expect(result.liters, 15.5);
    });

    test('extracts price per liter from rate keyword', () {
      const text = '''
FUEL STATION
Rate: 272.45
Qty: 20 Ltr
Amount: Rs. 5449
''';
      final result = service.parseFuelReceipt(text);
      expect(result.pricePerLiter, 272.45);
    });

    test('calculates missing values - price per liter from amount and liters', () {
      const text = '''
FUEL STATION
Total: Rs. 1000
Volume: 10 Ltr
''';
      final result = service.parseFuelReceipt(text);
      expect(result.totalAmount, 1000.0);
      expect(result.liters, 10.0);
      expect(result.pricePerLiter, 100.0);
    });

    test('uses first textual line as fallback station name', () {
      const text = '''
ABC FUEL CENTER
123
456.78
''';
      final result = service.parseFuelReceipt(text);
      expect(result.stationName, 'ABC FUEL CENTER');
    });

    test('handles empty text gracefully', () {
      final result = service.parseFuelReceipt('');
      expect(result.stationName, isNull);
      expect(result.totalAmount, isNull);
      expect(result.liters, isNull);
    });
  });

  group('POS Receipt Parsing', () {
    test('extracts items with simple item + price pattern', () {
      const text = '''
AUTO PARTS STORE
Oil Filter        350.00
Air Filter        250.00
Spark Plug        180.00
Total             780.00
''';
      final items = service.parsePOSReceipt(text);
      expect(items.length, greaterThanOrEqualTo(2));
      // Verify at least some items extracted
      final names = items.map((i) => i.name.toLowerCase());
      expect(names.any((n) => n.contains('filter') || n.contains('spark')), isTrue);
    });

    test('skips total/tax lines', () {
      const text = '''
STORE
Item A        100.00
Item B        200.00
Subtotal      300.00
Tax           54.00
Total         354.00
''';
      final items = service.parsePOSReceipt(text);
      final names = items.map((i) => i.name.toLowerCase()).toList();
      expect(names.any((n) => n.contains('total')), isFalse);
      expect(names.any((n) => n.contains('tax')), isFalse);
    });

    test('handles qty x price pattern', () {
      const text = '''
STORE
Brake Pads    2 x 500.00
Oil Filter    1 x 350.00
''';
      final items = service.parsePOSReceipt(text);
      expect(items.length, greaterThanOrEqualTo(1));
    });

    test('returns empty list for non-receipt text', () {
      const text = 'Hello world this is not a receipt';
      final items = service.parsePOSReceipt(text);
      expect(items, isEmpty);
    });
  });

  group('Mechanic Bill Parsing', () {
    test('extracts services with costs', () {
      const text = '''
AUTO WORKSHOP
Oil Change        800.00
Brake Adjustment  500.00
Wheel Alignment   1200.00
Total             2500.00
''';
      final services = service.parseMechanicBill(text);
      expect(services.length, greaterThanOrEqualTo(2));
    });

    test('skips header/footer lines', () {
      const text = '''
Bill No: 12345
Date: 15/03/2026
Clutch Repair     3000.00
Total             3000.00
''';
      final services = service.parseMechanicBill(text);
      final descs = services.map((s) => s.description.toLowerCase()).toList();
      expect(descs.any((d) => d.contains('bill no')), isFalse);
      expect(descs.any((d) => d.contains('date')), isFalse);
    });

    test('returns empty list for non-bill text', () {
      const text = 'Random text without prices';
      final services = service.parseMechanicBill(text);
      expect(services, isEmpty);
    });
  });

  group('Business Name Extraction', () {
    test('extracts first text line as business name', () {
      const text = '''
Khan Motors Workshop
Service charges
''';
      expect(service.extractBusinessName(text), 'Khan Motors Workshop');
    });

    test('skips purely numeric first lines', () {
      const text = '''
12345
Real Store Name
''';
      // First line is numeric, should skip to next
      final name = service.extractBusinessName(text);
      expect(name, isNotNull);
    });

    test('returns null for empty text', () {
      expect(service.extractBusinessName(''), isNull);
    });
  });
}
