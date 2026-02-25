part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class SubscribeToLogs extends DashboardEvent {}

class FuelLogsUpdated extends DashboardEvent {
  final List<FuelLogModel> logs;
  FuelLogsUpdated(this.logs);
}

class MaintenanceLogsUpdated extends DashboardEvent {
  final List<MaintenanceLogModel> logs;
  MaintenanceLogsUpdated(this.logs);
}
