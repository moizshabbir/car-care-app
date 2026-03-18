import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'ai_service.dart';

/// Represents the type of receipt detected
enum ReceiptType { fuel, pos, mechanic, unknown }

/// Parsed data from a fuel/petrol receipt
class ParsedFuelReceipt {
  final String? stationName;
  final double? totalAmount;
  final double? liters;
  final double? pricePerLiter;
  final String? location;

  ParsedFuelReceipt({
    this.stationName,
    this.totalAmount,
    this.liters,
    this.pricePerLiter,
    this.location,
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

  ParsedPOSReceipt({this.storeName, this.items = const [], this.totalAmount});
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

  ParsedMechanicBill({
    this.mechanicName,
    this.services = const [],
    this.totalAmount,
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
    final aiData = await _aiService.analyzeReceiptImage(bytes);
    
    if (aiData != null) {
      return ParsedFuelReceipt(
        stationName: aiData['name']?.toString(),
        totalAmount: _parseDouble(aiData['total_amount']),
        liters: _parseDouble(aiData['liter']),
        pricePerLiter: null, // Gemini can skip strict price per liter without affecting global logic
        location: null,
      );
    }
    
    return ParsedFuelReceipt();
  }

  /// Parse a POS/store receipt perfectly structured from JSON
  Future<ParsedPOSReceipt> parsePOSReceipt(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes);
    
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
      );
    }

    return ParsedPOSReceipt();
  }

  /// Parse a mechanic/repair bill perfectly structured from JSON
  Future<ParsedMechanicBill> parseMechanicBill(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes);
    
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
      );
    }

    return ParsedMechanicBill();
  }

  /// Master parsing function that lets Gemini classify the receipt
  Future<dynamic> parseAnyReceipt(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final aiData = await _aiService.analyzeReceiptImage(bytes);

    if (aiData == null) return null;

    final type = aiData['type']?.toString().toLowerCase();

    if (type == 'refuel') {
      return ParsedFuelReceipt(
        stationName: aiData['name']?.toString(),
        totalAmount: _parseDouble(aiData['total_amount']),
        liters: _parseDouble(aiData['liter']),
      );
    } else if (type == 'store') {
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

    return null; // Could not map
  }
}
