import 'dart:io';

import 'package:car_care_app/features/logs/data/models/fuel_log_model.dart';
import 'package:car_care_app/features/logs/data/models/location_model.dart';
import 'package:car_care_app/features/logs/data/repositories/log_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late LogRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FuelLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
       Hive.registerAdapter(LocationModelAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repository = LogRepositoryImpl(fakeFirestore);
    if (!Hive.isBoxOpen('fuel_logs')) {
      await Hive.openBox<FuelLogModel>('fuel_logs');
    }
    await Hive.box<FuelLogModel>('fuel_logs').clear();
  });

  test('addFuelLog saves to Hive and Firestore (Offline-First simulation)', () async {
    final log = FuelLogModel(
      id: 'test_id',
      odometer: 1000,
      liters: 50.0,
      cost: 100.0,
      timestamp: DateTime.now(),
      location: LocationModel(latitude: 0, longitude: 0, timestamp: DateTime.now()),
    );

    // This simulates calling the repository method.
    // In a real offline scenario, the Firestore SDK queues the write.
    // FakeCloudFirestore executes it immediately, but verifying it's called
    // ensures the repository is correctly attempting to sync.
    await repository.addFuelLog(log);

    // Verify Hive (Local persistence)
    final box = Hive.box<FuelLogModel>('fuel_logs');
    expect(box.get('test_id'), isNotNull);
    expect(box.get('test_id')!.odometer, 1000);

    // Verify Firestore (Remote sync)
    final doc = await fakeFirestore.collection('fuel_logs').doc('test_id').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['odometer'], 1000);
  });

  test('getRecentFuelLogs returns logs from Hive when available', () async {
    final log = FuelLogModel(
      id: 'test_id_local',
      odometer: 2000,
      liters: 50.0,
      cost: 100.0,
      timestamp: DateTime.now(),
      location: LocationModel(latitude: 0, longitude: 0, timestamp: DateTime.now()),
    );
    final box = Hive.box<FuelLogModel>('fuel_logs');
    await box.put(log.id, log);

    // Firestore is empty

    final result = await repository.getRecentFuelLogs();

    expect(result.length, 1);
    expect(result.first.id, 'test_id_local');
  });

  test('getRecentFuelLogs fetches from Firestore when Hive is empty and syncs to Hive', () async {
    // Hive is empty (cleared in setUp)

    // Add to Firestore manually to simulate remote data
    await fakeFirestore.collection('fuel_logs').doc('remote_id').set({
      'id': 'remote_id',
      'odometer': 3000,
      'liters': 60.0,
      'cost': 120.0,
      'timestamp': Timestamp.now(),
      'location': {
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': Timestamp.now(),
      }
    });

    final result = await repository.getRecentFuelLogs();

    expect(result.length, 1);
    expect(result.first.id, 'remote_id');
    expect(result.first.odometer, 3000);

    // Verify sync to Hive
    final box = Hive.box<FuelLogModel>('fuel_logs');
    expect(box.get('remote_id'), isNotNull);
  });
}
