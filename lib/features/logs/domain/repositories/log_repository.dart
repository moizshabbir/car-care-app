import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';

abstract class LogRepository {
  Future<void> addFuelLog(FuelLogModel log);
  Future<List<FuelLogModel>> getRecentFuelLogs();
  Future<void> addMaintenanceLog(MaintenanceLogModel log);
}
