import 'package:injectable/injectable.dart';

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
  /// Known fuel station brand keywords
  static const _fuelBrands = [
    'shell', 'hp', 'bharat', 'indian oil', 'iocl', 'bpcl', 'hpcl',
    'reliance', 'nayara', 'essar', 'chevron', 'total', 'caltex',
    'petrol', 'petroleum', 'fuel', 'filling station', 'gas station',
    'petrol pump', 'diesel', 'cng',
  ];

  /// Keywords that indicate a fuel receipt
  static const _fuelKeywords = [
    'petrol', 'diesel', 'fuel', 'liter', 'litre', 'ltr', 'gallon',
    'unleaded', 'premium', 'octane', 'nozzle', 'pump', 'filling',
    'cng', 'lpg', 'refuel', 'refueling',
  ];

  /// Keywords that indicate a POS/store receipt
  static const _posKeywords = [
    'invoice', 'receipt', 'bill', 'item', 'qty', 'quantity',
    'subtotal', 'sub-total', 'tax', 'gst', 'cgst', 'sgst',
    'total', 'mrp', 'discount', 'payment', 'cash', 'card',
    'upi', 'spare', 'part', 'filter', 'oil', 'brake', 'battery',
    'tyre', 'tire', 'wiper', 'coolant', 'accessory',
  ];

  /// Keywords that indicate a mechanic bill
  static const _mechanicKeywords = [
    'mechanic', 'workshop', 'garage', 'labour', 'labor',
    'service', 'repair', 'maintenance', 'denting', 'painting',
    'alignment', 'balancing', 'overhauling', 'tuning', 'wash',
    'fitting', 'replacement', 'charge', 'workmanship',
  ];

  /// Detect the type of receipt from OCR text
  ReceiptType detectReceiptType(String text) {
    final lower = text.toLowerCase();

    int fuelScore = 0;
    int posScore = 0;
    int mechanicScore = 0;

    for (var keyword in _fuelKeywords) {
      if (lower.contains(keyword)) fuelScore++;
    }
    for (var keyword in _posKeywords) {
      if (lower.contains(keyword)) posScore++;
    }
    for (var keyword in _mechanicKeywords) {
      if (lower.contains(keyword)) mechanicScore++;
    }

    // Check for fuel brands for a strong signal
    for (var brand in _fuelBrands) {
      if (lower.contains(brand)) fuelScore += 3;
    }

    if (fuelScore >= posScore && fuelScore >= mechanicScore && fuelScore > 0) {
      return ReceiptType.fuel;
    } else if (mechanicScore >= posScore && mechanicScore > 0) {
      return ReceiptType.mechanic;
    } else if (posScore > 0) {
      return ReceiptType.pos;
    }

    return ReceiptType.unknown;
  }

  /// Parse a fuel/petrol receipt
  ParsedFuelReceipt parseFuelReceipt(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final lower = text.toLowerCase();

    String? stationName;
    double? totalAmount;
    double? liters;
    double? pricePerLiter;
    String? location;

    // Extract station name: first line that contains a known brand, or the first non-numeric line
    for (var line in lines) {
      final lineLower = line.toLowerCase();
      for (var brand in _fuelBrands) {
        if (lineLower.contains(brand)) {
          stationName = line;
          break;
        }
      }
      if (stationName != null) break;
    }

    // Fallback: use first line if it looks like a name (not purely numbers)
    if (stationName == null && lines.isNotEmpty) {
      final firstLine = lines.first;
      if (RegExp(r'[a-zA-Z]').hasMatch(firstLine)) {
        stationName = firstLine;
      }
    }

    // Extract amounts using contextual keywords
    final amountPatterns = [
      RegExp(r'(?:total|amount|amt|net|sale)\s*[:\-=]?\s*(?:rs\.?|₹|inr)?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:rs\.?|₹|inr)\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (var pattern in amountPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && totalAmount == null) {
          totalAmount = val;
        }
      }
    }

    // Extract liters
    final literPatterns = [
      RegExp(r'([\d,]+\.?\d*)\s*(?:ltr|liter|litre|l)\b', caseSensitive: false),
      RegExp(r'(?:qty|quantity|volume)\s*[:\-=]?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (var pattern in literPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && liters == null) {
          liters = val;
        }
      }
    }

    // Extract price per liter
    final ratePatterns = [
      RegExp(r'(?:rate|price|price/l|price/ltr)\s*[:\-=]?\s*(?:rs\.?|₹)?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d]+\.\d{2})\s*(?:/l|/ltr|per\s*l)', caseSensitive: false),
    ];

    for (var pattern in ratePatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && pricePerLiter == null) {
          pricePerLiter = val;
        }
      }
    }

    // Calculate missing values if possible
    if (totalAmount != null && liters != null && pricePerLiter == null) {
      pricePerLiter = totalAmount / liters;
    } else if (totalAmount != null && pricePerLiter != null && liters == null) {
      liters = totalAmount / pricePerLiter;
    } else if (liters != null && pricePerLiter != null && totalAmount == null) {
      totalAmount = liters * pricePerLiter;
    }

    // Fallback: if we still don't have amount, try to find large numbers
    if (totalAmount == null) {
      final allNumbers = RegExp(r'[\d,]+\.?\d*').allMatches(text);
      final numbers = allNumbers
          .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '')))
          .where((n) => n != null && n > 0)
          .map((n) => n!)
          .toList();
      numbers.sort((a, b) => b.compareTo(a));

      for (var num in numbers) {
        if (num > 100 && totalAmount == null) {
          totalAmount = num;
        } else if (num > 1 && num < 200 && liters == null) {
          liters = num;
        }
      }
    }

    return ParsedFuelReceipt(
      stationName: stationName,
      totalAmount: totalAmount,
      liters: liters,
      pricePerLiter: pricePerLiter,
      location: location,
    );
  }

  /// Parse a POS/store receipt
  List<POSItem> parsePOSReceipt(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final items = <POSItem>[];

    // Pattern: "item name ... price" or "item name qty x price"
    final itemPattern = RegExp(
      r'^(.+?)\s+(\d+)\s*[xX×]\s*(?:rs\.?|₹)?\s*([\d,]+\.?\d*)\s*$',
    );
    final simpleItemPattern = RegExp(
      r'^(.+?)\s+(?:rs\.?|₹)?\s*([\d,]+\.?\d+)\s*$',
    );

    // Skip header and footer lines
    final skipKeywords = ['total', 'subtotal', 'sub-total', 'tax', 'gst',
      'sgst', 'cgst', 'discount', 'change', 'cash', 'card', 'upi',
      'thank', 'visit', 'invoice', 'bill', 'date', 'time', 'receipt'];

    for (var line in lines) {
      final lineLower = line.toLowerCase();

      // Skip header/footer lines
      bool skip = false;
      for (var keyword in skipKeywords) {
        if (lineLower.startsWith(keyword) || lineLower.contains('total')) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      // Try qty x price pattern first
      var match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final qty = int.tryParse(match.group(2)!) ?? 1;
        final price = double.tryParse(match.group(3)!.replaceAll(',', ''));
        if (name.isNotEmpty && price != null && price > 0) {
          items.add(POSItem(name: name, quantity: qty, price: price));
          continue;
        }
      }

      // Try simple item + price pattern
      match = simpleItemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final price = double.tryParse(match.group(2)!.replaceAll(',', ''));
        if (name.isNotEmpty && price != null && price > 0 && name.length > 2) {
          items.add(POSItem(name: name, quantity: 1, price: price));
        }
      }
    }

    return items;
  }

  /// Parse a mechanic/repair bill
  List<ServiceItem> parseMechanicBill(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final services = <ServiceItem>[];

    // Pattern: "service description ... cost"
    final servicePattern = RegExp(
      r'^(.+?)\s+(?:rs\.?|₹)?\s*([\d,]+\.?\d*)\s*$',
    );

    final skipKeywords = ['total', 'subtotal', 'grand total', 'tax', 'gst',
      'discount', 'paid', 'balance', 'date', 'bill no', 'invoice',
      'name', 'contact', 'phone', 'mobile', 'address'];

    for (var line in lines) {
      final lineLower = line.toLowerCase();

      bool skip = false;
      for (var keyword in skipKeywords) {
        if (lineLower.startsWith(keyword)) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      final match = servicePattern.firstMatch(line);
      if (match != null) {
        final desc = match.group(1)!.trim();
        final cost = double.tryParse(match.group(2)!.replaceAll(',', ''));
        if (desc.isNotEmpty && cost != null && cost > 0 && desc.length > 2) {
          services.add(ServiceItem(description: desc, cost: cost));
        }
      }
    }

    return services;
  }

  /// Extract store/mechanic name (typically the first line with text)
  String? extractBusinessName(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      if (RegExp(r'[a-zA-Z]').hasMatch(firstLine) && firstLine.length > 2) {
        return firstLine;
      }
    }
    return null;
  }
}
