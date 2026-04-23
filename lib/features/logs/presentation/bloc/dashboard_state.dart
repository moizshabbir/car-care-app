part of 'dashboard_bloc.dart';

enum DashboardStatus { loading, loaded, error }

enum LogType { fuel, service }

class DashboardLogItem extends Equatable {
  final dynamic originalLog;
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final LogType type;

  const DashboardLogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.originalLog,
  });

  @override
  List<Object?> get props => [id, title, subtitle, amount, date, type, originalLog];
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<FuelLogModel> fuelLogs;
  final List<MaintenanceLogModel> maintenanceLogs;

  // Stats
  final double avgCostPerKm;
  final double fuelEfficiency;
  final double totalFuelCost;
  final double totalMaintenanceCost;
  final double lastServiceCost;
  final DateTime? lastServiceDate;
  final DateTime? lastRefuelDate;
  final int odometer;
  final List<DashboardLogItem> recentLogs;
  final List<DashboardLogItem> allLogs;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.loading,
    this.fuelLogs = const [],
    this.maintenanceLogs = const [],
    this.avgCostPerKm = 0.0,
    this.fuelEfficiency = 0.0,
    this.totalFuelCost = 0.0,
    this.totalMaintenanceCost = 0.0,
    this.lastServiceCost = 0.0,
    this.lastServiceDate,
    this.lastRefuelDate,
    this.odometer = 0,
    this.recentLogs = const [],
    this.allLogs = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<FuelLogModel>? fuelLogs,
    List<MaintenanceLogModel>? maintenanceLogs,
    double? avgCostPerKm,
    double? fuelEfficiency,
    double? totalFuelCost,
    double? totalMaintenanceCost,
    double? lastServiceCost,
    DateTime? lastServiceDate,
    DateTime? lastRefuelDate,
    int? odometer,
    List<DashboardLogItem>? recentLogs,
    List<DashboardLogItem>? allLogs,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      fuelLogs: fuelLogs ?? this.fuelLogs,
      maintenanceLogs: maintenanceLogs ?? this.maintenanceLogs,
      avgCostPerKm: avgCostPerKm ?? this.avgCostPerKm,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      totalFuelCost: totalFuelCost ?? this.totalFuelCost,
      totalMaintenanceCost: totalMaintenanceCost ?? this.totalMaintenanceCost,
      lastServiceCost: lastServiceCost ?? this.lastServiceCost,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastRefuelDate: lastRefuelDate ?? this.lastRefuelDate,
      odometer: odometer ?? this.odometer,
      recentLogs: recentLogs ?? this.recentLogs,
      allLogs: allLogs ?? this.allLogs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        fuelLogs,
        maintenanceLogs,
        avgCostPerKm,
        totalFuelCost,
        totalMaintenanceCost,
        lastServiceCost,
        lastServiceDate,
        lastRefuelDate,
        odometer,
        recentLogs,
        allLogs,
        errorMessage,
      ];
}
