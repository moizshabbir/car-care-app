import 'package:flutter_test/flutter_test.dart';
import 'package:carlog/main.dart';
import 'package:carlog/injection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:carlog/features/logs/data/models/fuel_log_model.dart';
import 'package:carlog/features/logs/data/models/location_model.dart';
import 'package:carlog/features/logs/data/models/maintenance_log_model.dart';
import 'package:carlog/features/vehicles/data/models/vehicle_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<GoogleSignIn>(),
  MockSpec<FirebaseAnalytics>(),
  MockSpec<FirebasePerformance>(),
  MockSpec<FirebaseFirestore>(),
])
import 'app_startup_test.mocks.dart';

void main() {
  testWidgets('App should not get stuck initializing', (WidgetTester tester) async {
    print('Test Started');
    
    print('Initializing Hive...');
    Hive.init(Directory.systemTemp.path);
    try {
      Hive.registerAdapter(FuelLogModelAdapter());
      Hive.registerAdapter(LocationModelAdapter());
      Hive.registerAdapter(MaintenanceLogModelAdapter());
      Hive.registerAdapter(VehicleModelAdapter());
    } catch (e) {
      print('Hive adapters already registered? $e');
    }
    print('Hive Initialized');
    
    print('Configuring dependencies...');
    configureDependencies(environment: 'test');
    print('Dependencies configured');
    
    print('Pumping MyApp...');
    await tester.pumpWidget(const MyApp());
    print('Pumped MyApp, settling...');
    
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    print('Pumped twice');
    
    print('Test Finished');
  });
}
