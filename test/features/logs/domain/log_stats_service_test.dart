import 'package:carlog/features/logs/data/models/fuel_log_model.dart';
import 'package:carlog/features/logs/domain/log_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogStatsService statsService;

  setUp(() {
    statsService = LogStatsService();
  });

  group('LogStatsService', () {
    test('calculateAverageCostPerKm returns 0.0 for empty list', () {
      expect(statsService.calculateAverageCostPerKm([]), 0.0);
    });

    test('calculateFuelEfficiency returns correct value', () {
      final logs = [
        FuelLogModel(
          id: '1',
          odometer: 100,
          liters: 10,
          cost: 20,
          timestamp: DateTime.now(),
          userId: 'user1',
        ),
        FuelLogModel(
          id: '2',
          odometer: 200,
          liters: 10,
          cost: 25,
          timestamp: DateTime.now(),
          userId: 'user1',
        ),
      ];
      // Distance = 100. Liters = 10 (for the newest refill). Wait, calculation sums all except newest?
      // "for (int i = 0; i < logs.length - 1; i++) { totalLiters += logs[i].liters; }"
      // Where logs are sorted descending. newest is logs.first, oldest is logs.last.
      // logs.first (id 2) has liters=10. logs.last (id 1) has liters=10.
      // So totalLiters = 10. Distance = 100. Eff = 100 / 10 = 10.
      expect(statsService.calculateFuelEfficiency(logs), 10.0);
    });

    test('estimateNextOdometer calculates correctly', () {
      final logs = [
        FuelLogModel(
          id: '1',
          odometer: 100,
          liters: 10,
          cost: 20,
          timestamp: DateTime.now(),
          userId: 'user1',
        ),
        FuelLogModel(
          id: '2',
          odometer: 200,
          liters: 10,
          cost: 25,
          timestamp: DateTime.now(),
          userId: 'user1',
        ),
      ];
      expect(statsService.estimateNextOdometer(logs), 300);
    });
  });
}
