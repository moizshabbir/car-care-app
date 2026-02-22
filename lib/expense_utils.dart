class ExpenseUtils {
  /// Calculates the cost per kilometer.
  ///
  /// Formula: Total Cost / Total Kilometers.
  /// Returns 0.0 if [totalKilometers] is 0 or negative.
  /// Returns 0.0 if [totalCost] is negative.
  static double calculateCostPerKm(double totalCost, double totalKilometers) {
    if (totalKilometers <= 0 || totalCost < 0) {
      return 0.0;
    }
    return totalCost / totalKilometers;
  }
}
