import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@lazySingleton
class SettingsService extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'date_format';
  static const String _aiBaseUrlKey = 'ai_base_url';
  static const String _aiApiKeyKey = 'ai_api_key';
  static const String _aiModelKey = 'ai_model';

  late Box settingsBox;
  bool _isInitialized = false;
  final _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SettingsService(this._auth, this._firestore);

  Future<void> init() async {
    if (_isInitialized) return;
    settingsBox = await Hive.openBox(_boxName);
    _isInitialized = true;
    
    // Load cached AI API key
    _cachedAiApiKey = await _secureStorage.read(key: _aiApiKeyKey) ?? '';
    
    debugPrint('SETTINGS_SERVICE: Initialized box. Current currency: ${currency}');
    
    // Attempt to fetch from Firestore if logged in
    if (_auth.currentUser != null) {
      await _fetchFromFirestore();
    }
    
    // Listen for auth changes to sync
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchFromFirestore();
      }
    });
  }

  Future<void> _fetchFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      debugPrint('SETTINGS_SERVICE: Fetching from Firestore for user $uid...');
      final doc = await _firestore.collection('users').doc(uid).collection('config').doc('settings').get();
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('SETTINGS_SERVICE: Firestore data received: $data');
        
        if (data.containsKey(_currencyKey)) {
           await settingsBox.put(_currencyKey, data[_currencyKey]);
           _currencyController.add(data[_currencyKey]);
        }
        if (data.containsKey(_dateFormatKey)) {
           await settingsBox.put(_dateFormatKey, data[_dateFormatKey]);
           _dateFormatController.add(data[_dateFormatKey]);
        }
        if (data.containsKey(_aiBaseUrlKey)) await settingsBox.put(_aiBaseUrlKey, data[_aiBaseUrlKey]);
        if (data.containsKey(_aiModelKey)) await settingsBox.put(_aiModelKey, data[_aiModelKey]);
        
        // AI API Key is special (encrypted)
        if (data.containsKey(_aiApiKeyKey)) {
          final encrypted = data[_aiApiKeyKey] as String;
          final decrypted = _decrypt(encrypted);
          _cachedAiApiKey = decrypted;
          await _secureStorage.write(key: _aiApiKeyKey, value: decrypted);
        }
        
        notifyListeners();
        debugPrint('SETTINGS_SERVICE: Sync from Firestore complete. Currency: ${currency}');
      } else {
        debugPrint('SETTINGS_SERVICE: No settings found in Firestore. Syncing local to remote...');
        _syncToFirestore();
      }
    } catch (e) {
      debugPrint('SETTINGS_SERVICE Error fetching from Firestore: $e');
    }
  }

  Future<void> _syncToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final secureKey = await _secureStorage.read(key: _aiApiKeyKey) ?? '';
      final encryptedKey = _encrypt(secureKey);
      
      debugPrint('SETTINGS_SERVICE: Syncing to Firestore...');
      await _firestore.collection('users').doc(uid).collection('config').doc('settings').set({
        _currencyKey: currency,
        _dateFormatKey: dateFormat,
        _aiBaseUrlKey: aiBaseUrl,
        _aiModelKey: aiModel,
        _aiApiKeyKey: encryptedKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('SETTINGS_SERVICE: Sync to Firestore successful');
    } catch (e) {
      debugPrint('SETTINGS_SERVICE Error syncing to Firestore: $e');
    }
  }

  // Simple obfuscation/encryption for the key in Firestore
  // In a real app, use a more secure method or Vault
  String _encrypt(String text) {
    if (text.isEmpty) return '';
    return base64.encode(utf8.encode(text).map((b) => b ^ 42).toList());
  }

  String _decrypt(String encrypted) {
    if (encrypted.isEmpty) return '';
    try {
      final decoded = base64.decode(encrypted);
      return utf8.decode(decoded.map((b) => b ^ 42).toList());
    } catch (e) {
      return '';
    }
  }

  final _currencyController = StreamController<String>.broadcast();
  final _dateFormatController = StreamController<String>.broadcast();

  Stream<String> get currencyStream => _currencyController.stream;
  Stream<String> get dateFormatStream => _dateFormatController.stream;

  String get currency {
    if (!_isInitialized) return r'$';
    return settingsBox.get(_currencyKey, defaultValue: r'$');
  }
  
  Future<void> setCurrency(String value) async {
    debugPrint('SETTINGS_SERVICE: Saving currency: $value');
    await settingsBox.put(_currencyKey, value);
    _currencyController.add(value);
    _syncToFirestore();
    notifyListeners();
  }

  String get dateFormat {
    if (!_isInitialized) return 'dd/MM/yyyy';
    return settingsBox.get(_dateFormatKey, defaultValue: 'dd/MM/yyyy');
  }

  Future<void> setDateFormat(String value) async {
    debugPrint('SETTINGS_SERVICE: Saving date format: $value');
    await settingsBox.put(_dateFormatKey, value);
    _dateFormatController.add(value);
    _syncToFirestore();
    notifyListeners();
  }

  String get aiBaseUrl => settingsBox.get(_aiBaseUrlKey, defaultValue: '');
  Future<void> setAiBaseUrl(String value) async {
    await settingsBox.put(_aiBaseUrlKey, value);
    _syncToFirestore();
    notifyListeners();
  }

  // AI API Key is stored in Secure Storage
  String _cachedAiApiKey = '';
  String get aiApiKey {
    // This is synchronous, so we return a cached value
    // The value should be loaded during init()
    return _cachedAiApiKey;
  }

  Future<void> setAiApiKey(String value) async {
    _cachedAiApiKey = value;
    await _secureStorage.write(key: _aiApiKeyKey, value: value);
    _syncToFirestore();
    notifyListeners();
  }

  String get aiModel => settingsBox.get(_aiModelKey, defaultValue: '');
  Future<void> setAiModel(String value) async {
    await settingsBox.put(_aiModelKey, value);
    _syncToFirestore();
    notifyListeners();
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

  @override
  @disposeMethod
  void dispose() {
    _currencyController.close();
    _dateFormatController.close();
    super.dispose();
  }
}
