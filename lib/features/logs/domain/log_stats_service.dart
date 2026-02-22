import '../data/models/fuel_log_model.dart';

class LogStatsService {
  double calculateAverageCostPerKm(List<FuelLogModel> inputLogs) {
    if (inputLogs.length < 2) {
      return 0.0;
    }

    // Create a copy and sort by odometer descending (newest first)
    final logs = List<FuelLogModel>.from(inputLogs);
    logs.sort((a, b) => b.odometer.compareTo(a.odometer));

    final newest = logs.first;
    final oldest = logs.last;

    final distance = newest.odometer - oldest.odometer;

    if (distance <= 0) {
      return 0.0;
    }

    // Sum costs of all logs except the oldest one.
    // We assume full tank refills for accurate calculation.
    // Cost associated with the distance covered (Oldest -> Newest) is the sum of costs of refills
    // that happened *after* the Oldest one, up to and including the Newest one.
    // Example:
    // Log A (Odo 100) - Start.
    // Log B (Odo 200, Cost 20) - Refill. Distance 100-200 consumed this fuel? No, this fuel REPLACES what was consumed.
    // So Cost 20 corresponds to fuel used for 100->200.
    // Log C (Odo 300, Cost 15) - Refill. Distance 200-300 consumed fuel costing 15.
    // Total Distance: 200. Total Cost: 20+15 = 35.
    // So we sum costs of Newest...Oldest+1.
    // i.e., indices 0 to logs.length - 2.

    double totalCost = 0.0;
    for (int i = 0; i < logs.length - 1; i++) {
        totalCost += logs[i].cost;
    }

    return totalCost / distance;
  }
}
