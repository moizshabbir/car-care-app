import 'dart:io';
import 'package:carlog/features/vehicles/data/models/vehicle_model.dart';
import 'package:carlog/features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late VehicleRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_user_id');

    repository = VehicleRepositoryImpl(fakeFirestore, mockFirebaseAuth);
    if (!Hive.isBoxOpen('vehicles')) {
      await Hive.openBox<VehicleModel>('vehicles');
    }
    await Hive.box<VehicleModel>('vehicles').clear();
  });

  final tVehicle = VehicleModel(
    id: 'test_vehicle',
    name: 'My Car',
    make: 'Toyota',
    model: 'Corolla',
    year: 2020,
    userId: 'test_user_id',
  );

  group('VehicleRepositoryImpl', () {
    test('addVehicle saves to Hive and Firestore', () async {
      await repository.addVehicle(tVehicle);

      // Verify Hive
      final box = Hive.box<VehicleModel>('vehicles');
      expect(box.get('test_vehicle'), isNotNull);
      expect(box.get('test_vehicle')!.name, 'My Car');

      // Verify Firestore
      final doc = await fakeFirestore.collection('vehicles').doc('test_vehicle').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'My Car');
    });

    test('updateVehicle updates Hive and Firestore', () async {
      await repository.addVehicle(tVehicle);
      
      final updatedVehicle = VehicleModel(
        id: 'test_vehicle',
        name: 'My Updated Car',
        make: 'Toyota',
        model: 'Corolla',
        year: 2021,
        userId: 'test_user_id',
      );

      await repository.updateVehicle(updatedVehicle);

      // Verify Hive
      final box = Hive.box<VehicleModel>('vehicles');
      expect(box.get('test_vehicle')!.name, 'My Updated Car');

      // Verify Firestore
      final doc = await fakeFirestore.collection('vehicles').doc('test_vehicle').get();
      expect(doc.data()!['name'], 'My Updated Car');
    });

    test('deleteVehicle removes from Hive and Firestore', () async {
      await repository.addVehicle(tVehicle);
      
      await repository.deleteVehicle('test_vehicle');

      // Verify Hive
      final box = Hive.box<VehicleModel>('vehicles');
      expect(box.get('test_vehicle'), isNull);

      // Verify Firestore
      final doc = await fakeFirestore.collection('vehicles').doc('test_vehicle').get();
      expect(doc.exists, isFalse);
    });

    test('getVehiclesStream emits vehicles from Firestore', () async {
      await fakeFirestore.collection('vehicles').doc('v1').set(tVehicle.toJson());
      
      final stream = repository.getVehiclesStream();
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.name, 'My Car');
    });
  });
}
