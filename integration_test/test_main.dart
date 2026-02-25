import 'dart:async';
import 'dart:io';

import 'package:car_care_app/core/services/analytics_service.dart';
import 'package:car_care_app/core/services/location_service.dart';
import 'package:car_care_app/core/services/ocr_service.dart';
import 'package:car_care_app/features/logs/data/models/fuel_log_model.dart';
import 'package:car_care_app/features/logs/data/models/location_model.dart';
import 'package:car_care_app/features/logs/data/models/maintenance_log_model.dart';
import 'package:car_care_app/features/logs/data/repositories/log_repository_impl.dart';
import 'package:car_care_app/features/logs/domain/repositories/log_repository.dart';
import 'package:car_care_app/features/logs/presentation/bloc/expense_log_bloc.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_bloc.dart';
import 'package:car_care_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Manual Fakes
class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}
  @override
  Future<void> logLogStart() async {}
  @override
  Future<void> logLogCompleted(bool success) async {}
  @override
  Future<void> logShareCardClicked() async {}
  @override
  Future<void> logOCRManualEdit(String field) async {}
  @override
  Future<void> startTimer(String name) async {}
  @override
  Future<void> stopTimer(String name) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOCRService implements OCRService {
  @override
  Future<RecognizedText> processImage(InputImage inputImage) async {
    throw UnimplementedError();
  }
  @override
  Future<void> close() async {}
}

class FakeLocationService implements LocationService {
  @override
  Future<Position?> getCurrentLocation() async {
    return Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mock Camera Channel
  const MethodChannel('plugins.flutter.io/camera')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'availableCameras') {
      return [];
    }
    return null;
  });

  // Mock Path Provider
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory' ||
        methodCall.method == 'getApplicationSupportDirectory' ||
        methodCall.method == 'getTemporaryDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  // Initialize Hive
  // Use temp directory for test to avoid path_provider dependency
  final tempDir = await Directory.systemTemp.createTemp();
  Hive.init(tempDir.path);

  // Register Adapters
  if (!Hive.isAdapterRegistered(FuelLogModelAdapter().typeId)) {
     Hive.registerAdapter(FuelLogModelAdapter());
  }
  if (!Hive.isAdapterRegistered(LocationModelAdapter().typeId)) {
     Hive.registerAdapter(LocationModelAdapter());
  }
  if (!Hive.isAdapterRegistered(MaintenanceLogModelAdapter().typeId)) {
     Hive.registerAdapter(MaintenanceLogModelAdapter());
  }

  // Override GetIt registrations
  final getIt = GetIt.instance;
  getIt.allowReassignment = true;

  // Fake Firestore
  final fakeFirestore = FakeFirebaseFirestore();

  // Register Dependencies
  getIt.registerSingleton<FirebaseFirestore>(fakeFirestore);

  getIt.registerSingleton<AnalyticsService>(FakeAnalyticsService());
  getIt.registerSingleton<OCRService>(FakeOCRService());
  getIt.registerSingleton<LocationService>(FakeLocationService());

  // Repository using FakeFirestore
  getIt.registerLazySingleton<LogRepository>(() => LogRepositoryImpl(getIt<FirebaseFirestore>()));

  // BLoCs
  getIt.registerFactory<QuickLogBloc>(() => QuickLogBloc(
        getIt<OCRService>(),
        getIt<LocationService>(),
        getIt<LogRepository>(),
      ));

  getIt.registerFactory<ExpenseLogBloc>(() => ExpenseLogBloc(getIt<LogRepository>()));

  // Run App
  runApp(const MyApp());
}
