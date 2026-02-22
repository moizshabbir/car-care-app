import '../../data/models/fuel_log_model.dart';

abstract class LogRepository {
  Future<void> addFuelLog(FuelLogModel log);
  Future<List<FuelLogModel>> getRecentFuelLogs();
}
