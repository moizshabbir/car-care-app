part of 'dashboard_bloc.dart';

enum DashboardStatus { loading, loaded, error }

enum LogType { fuel, service }

class DashboardLogItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final LogType type;

  DashboardLogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class DashboardState {
  final DashboardStatus status;
  final List<FuelLogModel> fuelLogs;
  final List<MaintenanceLogModel> maintenanceLogs;

  // Stats
  final double avgCostPerKm;
  final double totalFuelCost;
  final double totalMaintenanceCost;
  final double lastServiceCost;
  final DateTime? lastServiceDate;
  final DateTime? lastRefuelDate;
  final int odometer;
  final List<DashboardLogItem> recentLogs;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.loading,
    this.fuelLogs = const [],
    this.maintenanceLogs = const [],
    this.avgCostPerKm = 0.0,
    this.totalFuelCost = 0.0,
    this.totalMaintenanceCost = 0.0,
    this.lastServiceCost = 0.0,
    this.lastServiceDate,
    this.lastRefuelDate,
    this.odometer = 0,
    this.recentLogs = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<FuelLogModel>? fuelLogs,
    List<MaintenanceLogModel>? maintenanceLogs,
    double? avgCostPerKm,
    double? totalFuelCost,
    double? totalMaintenanceCost,
    double? lastServiceCost,
    DateTime? lastServiceDate,
    DateTime? lastRefuelDate,
    int? odometer,
    List<DashboardLogItem>? recentLogs,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      fuelLogs: fuelLogs ?? this.fuelLogs,
      maintenanceLogs: maintenanceLogs ?? this.maintenanceLogs,
      avgCostPerKm: avgCostPerKm ?? this.avgCostPerKm,
      totalFuelCost: totalFuelCost ?? this.totalFuelCost,
      totalMaintenanceCost: totalMaintenanceCost ?? this.totalMaintenanceCost,
      lastServiceCost: lastServiceCost ?? this.lastServiceCost,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastRefuelDate: lastRefuelDate ?? this.lastRefuelDate,
      odometer: odometer ?? this.odometer,
      recentLogs: recentLogs ?? this.recentLogs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
