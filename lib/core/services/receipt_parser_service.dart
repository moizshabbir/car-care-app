import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
export 'ai_service.dart';
import 'ai_service.dart';

/// Parsed data from a fuel/petrol receipt
class ParsedFuelReceipt {
  final String? stationName;
  final double? totalAmount;
  final double? liters;
  final double? pricePerLiter;
  final String? location;

  final String? currency;
  final double? odometer;

  ParsedFuelReceipt({
    this.stationName,
    this.totalAmount,
    this.liters,
    this.pricePerLiter,
    this.location,
    this.currency,
    this.odometer,
  });

  @override
  String toString() =>
      'ParsedFuelReceipt(station: $stationName, amount: $totalAmount, liters: $liters, price/L: $pricePerLiter, location: $location)';
}

/// A single item from a POS receipt
class POSItem {
  final String name;
  final int quantity;
  final double price;

  POSItem({required this.name, this.quantity = 1, required this.price});

  @override
  String toString() => 'POSItem(name: $name, qty: $quantity, price: $price)';
}

/// Parsed data from a POS/store receipt
class ParsedPOSReceipt {
  final String? storeName;
  final List<POSItem> items;
  final double? totalAmount;

  final String? currency;
  final double? odometer;

  ParsedPOSReceipt({this.storeName, this.items = const [], this.totalAmount, this.currency, this.odometer});
}

/// A single service item from a mechanic bill
class ServiceItem {
  final String description;
  final double cost;

  ServiceItem({required this.description, required this.cost});

  @override
  String toString() => 'ServiceItem(desc: $description, cost: $cost)';
}

/// Parsed data from a mechanic/repair bill
class ParsedMechanicBill {
  final String? mechanicName;
  final List<ServiceItem> services;
  final double? totalAmount;

  final String? currency;
  final double? odometer;

  ParsedMechanicBill({
    this.mechanicName,
    this.services = const [],
    this.totalAmount,
    this.currency,
    this.odometer,
  });
}

@lazySingleton
class ReceiptParserService {
  final AIService _aiService;

  ReceiptParserService(this._aiService);

  /// Helper to convert dynamic AI numbers to double safely
  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) {
      final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
      return parsed;
    }
    return null;
  }
  
  int _parseInt(dynamic val) {
    if (val == null) return 1;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
      return parsed ?? 1;
    }
    return 1;
  }

  /// Parse a fuel/petrol receipt perfectly structured from JSON
  Future<ParsedFuelReceipt> parseFuelReceipt(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes, typeHint: ReceiptType.fuel);
    
    if (aiData != null) {
      debugPrint('PARSER_SERVICE: Mapping Fuel Receipt data: $aiData');
      return ParsedFuelReceipt(
        stationName: aiData['name']?.toString(),
        totalAmount: _parseDouble(aiData['total_amount']),
        liters: _parseDouble(aiData['liter']),
        pricePerLiter: _parseDouble(aiData['price_per_liter']),
        location: null,
        currency: aiData['currency']?.toString(),
        odometer: _parseDouble(aiData['odometer']),
      );
    }
    
    return ParsedFuelReceipt();
  }

  /// Parse a POS/store receipt perfectly structured from JSON
  Future<ParsedPOSReceipt> parsePOSReceipt(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes, typeHint: ReceiptType.pos);
    
    if (aiData != null && aiData['items'] != null) {
      final List<dynamic> itemsData = aiData['items'];
      final parsedItems = itemsData.map((item) => POSItem(
        name: item['name']?.toString() ?? 'Unknown',
        quantity: _parseInt(item['qty']),
        price: _parseDouble(item['price']) ?? 0.0,
      )).toList();

      return ParsedPOSReceipt(
        storeName: aiData['name']?.toString(),
        items: parsedItems,
        totalAmount: _parseDouble(aiData['total_amount']),
        currency: aiData['currency']?.toString(),
      );
    }

    return ParsedPOSReceipt();
  }

  /// Parse a mechanic/repair bill perfectly structured from JSON
  Future<ParsedMechanicBill> parseMechanicBill(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes, typeHint: ReceiptType.mechanic);
    
    if (aiData != null && aiData['items'] != null) {
      final List<dynamic> servicesData = aiData['items'];
      final services = servicesData.map((service) => ServiceItem(
        description: service['name']?.toString() ?? 'Unknown',
        cost: _parseDouble(service['price']) ?? 0.0,
      )).toList();

      return ParsedMechanicBill(
        mechanicName: aiData['name']?.toString(),
        services: services,
        totalAmount: _parseDouble(aiData['total_amount']),
        currency: aiData['currency']?.toString(),
      );
    }

    return ParsedMechanicBill();
  }

  String _normalizeType(String? rawType) {
    if (rawType == null) return 'unknown';

    final t = rawType.toLowerCase();

    if (['refuel', 'fuel', 'petrol', 'gas'].contains(t)) {
      return 'refuel';
    }

    if (['store', 'pos', 'shop', 'mart'].contains(t)) {
      return 'store';
    }

    if (['mechanic', 'repair', 'service', 'garage'].contains(t)) {
      return 'mechanic';
    }

    return 'unknown';
  }

  /// Master parsing function that lets Gemini classify the receipt
  Future<dynamic> parseAnyReceipt(String imagePath, {ReceiptType? typeHint}) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes, typeHint: typeHint);

    if (aiData == null) {
      debugPrint('PARSER_SERVICE: AI returned null data for the image.');
      return null;
    }

    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.log('AI RAW RESPONSE: $aiData');
    }

    final rawType = aiData['type']?.toString();
    String type = _normalizeType(rawType);
    
    // Fallback Classification
    if (type == 'unknown') {
      if (aiData['liter'] != null) {
        type = 'refuel';
      } else if (aiData['items'] != null && aiData['labor_cost'] != null) {
        type = 'mechanic';
      } else if (aiData['items'] != null) {
        type = 'store';
      }
    }

    debugPrint('PARSER_SERVICE: AI classified receipt as normalized type: "$type"');

    if (type == 'refuel') {
      debugPrint('PARSER_SERVICE: Mapping to ParsedFuelReceipt with data: $aiData');
      return ParsedFuelReceipt(
        stationName: aiData['name']?.toString(),
        totalAmount: _parseDouble(aiData['total_amount']),
        liters: _parseDouble(aiData['liter']),
        currency: aiData['currency']?.toString(),
        odometer: _parseDouble(aiData['odometer']),
      );
    } else if (type == 'store') {
      debugPrint('PARSER_SERVICE: Mapping to ParsedPOSReceipt');
      final itemsData = aiData['items'] as List<dynamic>? ?? [];
      return ParsedPOSReceipt(
        storeName: aiData['name']?.toString(),
        items: itemsData.map((item) => POSItem(
          name: item['name']?.toString() ?? 'Unknown',
          quantity: _parseInt(item['qty']),
          price: _parseDouble(item['price']) ?? 0.0,
        )).toList(),
        totalAmount: _parseDouble(aiData['total_amount']),
      );
    } else if (type == 'mechanic') {
      debugPrint('PARSER_SERVICE: Mapping to ParsedMechanicBill');
      final servicesData = aiData['items'] as List<dynamic>? ?? [];
      return ParsedMechanicBill(
        mechanicName: aiData['name']?.toString(),
        services: servicesData.map((service) => ServiceItem(
          description: service['name']?.toString() ?? 'Unknown',
          cost: _parseDouble(service['price']) ?? 0.0,
        )).toList(),
        totalAmount: _parseDouble(aiData['total_amount']),
      );
    }

    debugPrint('PARSER_SERVICE Error: Unknown or missing type in AI response: "$rawType" normalized to "$type"');
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.log('PARSER_SERVICE Failed to map normalized type "$type" from raw "$rawType"');
    }
    return null; // Could not map
  }
}
