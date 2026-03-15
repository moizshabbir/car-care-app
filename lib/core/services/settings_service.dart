import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SettingsService {
  static const String _boxName = 'settings';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'date_format';

  late Box settingsBox;

  Future<void> init() async {
    settingsBox = await Hive.openBox(_boxName);
  }

  final _currencyController = StreamController<String>.broadcast();
  final _dateFormatController = StreamController<String>.broadcast();

  Stream<String> get currencyStream => _currencyController.stream;
  Stream<String> get dateFormatStream => _dateFormatController.stream;

  String get currency {
    return settingsBox.get(_currencyKey, defaultValue: r'$');
  }
  
  Future<void> setCurrency(String value) async {
    await settingsBox.put(_currencyKey, value);
    _currencyController.add(value);
  }

  String get dateFormat {
    return settingsBox.get(_dateFormatKey, defaultValue: 'dd/MM/yyyy');
  }

  Future<void> setDateFormat(String value) async {
    await settingsBox.put(_dateFormatKey, value);
    _dateFormatController.add(value);
  }

  Future<void> detectAndSetCurrency() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        String? countryCode = placemarks.first.isoCountryCode;
        String currency = _mapCountryToCurrency(countryCode);
        await setCurrency(currency);
      }
    } catch (e) {
      debugPrint('Error detecting currency: $e');
    }
  }

  String _mapCountryToCurrency(String? countryCode) {
    switch (countryCode) {
      case 'IN': return '₹';
      case 'US': return r'$';
      case 'GB': return '£';
      case 'EU': return '€';
      case 'JP': return '¥';
      case 'PK': return 'Rs.';
      default: return r'$';
    }
  }

  @disposeMethod
  void dispose() {
    _currencyController.close();
    _dateFormatController.close();
  }
}
