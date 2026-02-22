import 'package:flutter_test/flutter_test.dart';
import 'package:car_care_app/expense_utils.dart';

void main() {
  group('ExpenseUtils - calculateCostPerKm', () {
    test('should calculate cost per km correctly for positive values', () {
      final result = ExpenseUtils.calculateCostPerKm(100.0, 500.0);
      expect(result, 0.2);
    });

    test('should return 0.0 when total kilometers is 0', () {
      final result = ExpenseUtils.calculateCostPerKm(100.0, 0.0);
      expect(result, 0.0);
    });

    test('should return 0.0 when total kilometers is negative', () {
      final result = ExpenseUtils.calculateCostPerKm(100.0, -10.0);
      expect(result, 0.0);
    });

    test('should return 0.0 when total cost is 0', () {
      final result = ExpenseUtils.calculateCostPerKm(0.0, 500.0);
      expect(result, 0.0);
    });

    test('should return 0.0 when total cost is negative', () {
      final result = ExpenseUtils.calculateCostPerKm(-50.0, 500.0);
      expect(result, 0.0);
    });

    test('should handle very small cost per km', () {
      final result = ExpenseUtils.calculateCostPerKm(1.0, 1000.0);
      expect(result, 0.001);
    });

    test('should handle large values', () {
      final result = ExpenseUtils.calculateCostPerKm(1000000.0, 10000.0);
      expect(result, 100.0);
    });
  });
}
