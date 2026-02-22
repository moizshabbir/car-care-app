import 'package:car_care_app/features/logs/data/models/fuel_log_model.dart';
import 'package:car_care_app/features/logs/data/models/location_model.dart';
import 'package:car_care_app/features/logs/domain/log_stats_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogStatsService service;

  setUp(() {
    service = LogStatsService();
  });

  final mockLocation = LocationModel(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
  );

  FuelLogModel createLog(String id, int odometer, double cost, DateTime timestamp) {
    return FuelLogModel(
      id: id,
      odometer: odometer,
      liters: 10.0, // Irrelevant for this test
      cost: cost,
      timestamp: timestamp,
      location: mockLocation,
    );
  }

  group('LogStatsService', () {
    test('calculateAverageCostPerKm returns 0.0 for empty list', () {
      expect(service.calculateAverageCostPerKm([]), 0.0);
    });

    test('calculateAverageCostPerKm returns 0.0 for single log', () {
      final logs = [
        createLog('1', 1000, 50.0, DateTime.now()),
      ];
      expect(service.calculateAverageCostPerKm(logs), 0.0);
    });

    test('calculateAverageCostPerKm returns 0.0 if distance is 0', () {
      final logs = [
        createLog('1', 1000, 50.0, DateTime.now()),
        createLog('2', 1000, 60.0, DateTime.now().subtract(const Duration(days: 1))),
      ];
      expect(service.calculateAverageCostPerKm(logs), 0.0);
    });

    test('calculateAverageCostPerKm calculates correctly for 2 logs', () {
      // Log 1: Odo 100, Cost 20 (Oldest)
      // Log 2: Odo 200, Cost 30 (Newest)
      // Distance: 200 - 100 = 100
      // Cost: Sum of costs (Newest...Oldest+1).
      // Here: index 0 (Newest) is Log 2. index 1 is Log 1.
      // Loop goes i=0 to < 1. So it sums logs[0].cost = 30.
      // Result: 30 / 100 = 0.3

      final logs = [
        createLog('1', 100, 20.0, DateTime(2023, 1, 1)),
        createLog('2', 200, 30.0, DateTime(2023, 1, 2)),
      ];

      expect(service.calculateAverageCostPerKm(logs), 0.3);
    });

    test('calculateAverageCostPerKm calculates correctly for multiple logs', () {
      // Log 1: Odo 100, Cost 20 (Oldest)
      // Log 2: Odo 200, Cost 30
      // Log 3: Odo 300, Cost 40 (Newest)

      // Sorted: Log 3, Log 2, Log 1
      // Distance: 300 - 100 = 200
      // Cost Sum: Log 3 (40) + Log 2 (30) = 70
      // Result: 70 / 200 = 0.35

      final logs = [
        createLog('1', 100, 20.0, DateTime(2023, 1, 1)),
        createLog('2', 200, 30.0, DateTime(2023, 1, 2)),
        createLog('3', 300, 40.0, DateTime(2023, 1, 3)),
      ];

      expect(service.calculateAverageCostPerKm(logs), 0.35);
    });

    test('calculateAverageCostPerKm handles unsorted input', () {
      final logs = [
        createLog('2', 200, 30.0, DateTime(2023, 1, 2)),
        createLog('1', 100, 20.0, DateTime(2023, 1, 1)),
        createLog('3', 300, 40.0, DateTime(2023, 1, 3)),
      ];

      expect(service.calculateAverageCostPerKm(logs), 0.35);
    });
  });
}
