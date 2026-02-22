import 'package:car_care_app/features/logs/data/models/fuel_log_model.dart';
import 'package:car_care_app/features/logs/data/models/location_model.dart';
import 'package:car_care_app/features/logs/data/models/maintenance_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuelLogModel', () {
    test('serialization to/from JSON works with Timestamp', () {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(1600000000000);
      final location = LocationModel(
        latitude: 10.0,
        longitude: 20.0,
        timestamp: timestamp,
      );
      final model = FuelLogModel(
        id: '1',
        odometer: 1000,
        liters: 50.0,
        cost: 100.0,
        timestamp: timestamp,
        location: location,
      );

      final json = model.toJson();
      expect(json['odometer'], 1000);
      expect(json['timestamp'], isA<Timestamp>());
      expect((json['timestamp'] as Timestamp).toDate(), timestamp);
      expect(json['location'], isA<Map<String, dynamic>>());
      expect((json['location'] as Map)['latitude'], 10.0);

      final fromJson = FuelLogModel.fromJson(json);
      expect(fromJson.odometer, model.odometer);
      expect(fromJson.timestamp, model.timestamp);
      expect(fromJson.location.latitude, model.location.latitude);
    });
  });

  group('MaintenanceLogModel', () {
    test('serialization to/from JSON works with Timestamp', () {
      final date = DateTime.fromMillisecondsSinceEpoch(1600000000000);
      final model = MaintenanceLogModel(
        id: '2',
        date: date,
        category: 'Repair',
        cost: 200.0,
        note: 'Oil change',
        photoPath: '/path/to/photo.jpg',
      );

      final json = model.toJson();
      expect(json['category'], 'Repair');
      expect(json['date'], isA<Timestamp>());
      expect((json['date'] as Timestamp).toDate(), date);

      final fromJson = MaintenanceLogModel.fromJson(json);
      expect(fromJson.category, model.category);
      expect(fromJson.date, model.date);
    });
  });
}
