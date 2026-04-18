import '../data/models/fuel_log_model.dart';

class LogStatsService {
  double calculateAverageCostPerKm(List<FuelLogModel> inputLogs) {
    if (inputLogs.length < 2) {
      return 0.0;
    }

    final logs = List<FuelLogModel>.from(inputLogs);
    logs.sort((a, b) => b.odometer.compareTo(a.odometer));

    final newest = logs.first;
    final oldest = logs.last;

    final distance = newest.odometer - oldest.odometer;

    if (distance <= 0) {
      return 0.0;
    }

    double totalCost = 0.0;
    for (int i = 0; i < logs.length - 1; i++) {
        totalCost += logs[i].cost;
    }

    return totalCost / distance;
  }

  double calculateTotalSpent(List<FuelLogModel> inputLogs) {
    return inputLogs.fold(0.0, (sum, log) => sum + log.cost);
  }

  double calculateTotalDistance(List<FuelLogModel> inputLogs) {
    if (inputLogs.isEmpty) return 0.0;

    final logs = List<FuelLogModel>.from(inputLogs);
    logs.sort((a, b) => a.odometer.compareTo(b.odometer));

    final minOdo = logs.first.odometer;
    final maxOdo = logs.last.odometer;

    return (maxOdo - minOdo).toDouble();
  }

  double calculateFuelEfficiency(List<FuelLogModel> inputLogs) {
    if (inputLogs.length < 2) return 0.0;

    final logs = List<FuelLogModel>.from(inputLogs);
    logs.sort((a, b) => b.odometer.compareTo(a.odometer));

    final newest = logs.first;
    final oldest = logs.last;

    final distance = newest.odometer - oldest.odometer;
    if (distance <= 0) return 0.0;

    double totalLiters = 0.0;
    for (int i = 0; i < logs.length - 1; i++) {
        totalLiters += logs[i].liters;
    }

    if (totalLiters == 0) return 0.0;
    return distance / totalLiters;
  }

  int estimateNextOdometer(List<FuelLogModel> inputLogs) {
    if (inputLogs.isEmpty) return 0;
    if (inputLogs.length == 1) return inputLogs.first.odometer;

    final logs = List<FuelLogModel>.from(inputLogs);
    logs.sort((a, b) => b.odometer.compareTo(a.odometer));

    final newest = logs.first;
    final oldest = logs.last;

    final distance = newest.odometer - oldest.odometer;
    final avgDistancePerLog = distance ~/ (logs.length - 1);

    return newest.odometer + avgDistancePerLog;
  }
}
