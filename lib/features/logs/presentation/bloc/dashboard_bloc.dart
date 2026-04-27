import 'dart:async';

import 'package:intl/intl.dart';
import '../../../../injection.dart';
import '../../../../core/services/settings_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/log_stats_service.dart';
import '../../domain/repositories/log_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final LogRepository _logRepository;
  final SettingsService _settingsService;
  final LogStatsService _statsService;

  StreamSubscription? _fuelSubscription;
  StreamSubscription? _maintenanceSubscription;

  DashboardBloc(this._logRepository, this._settingsService)
      : _statsService = LogStatsService(),
        super(const DashboardState()) {
    on<SubscribeToLogs>(_onSubscribeToLogs);
    on<FuelLogsUpdated>(_onFuelLogsUpdated);
    on<MaintenanceLogsUpdated>(_onMaintenanceLogsUpdated);
  }

  void _onSubscribeToLogs(SubscribeToLogs event, Emitter<DashboardState> emit) {
    emit(state.copyWith(status: DashboardStatus.loading));

    final vehicleId = event.vehicleId;
    if (vehicleId == null) {
      emit(state.copyWith(status: DashboardStatus.loaded));
      return;
    }

    _fuelSubscription?.cancel();
    _fuelSubscription = _logRepository.getFuelLogsStream(vehicleId).listen((logs) {
      add(FuelLogsUpdated(logs));
    });

    _maintenanceSubscription?.cancel();
    _maintenanceSubscription = _logRepository.getMaintenanceLogsStream(vehicleId).listen((logs) {
      add(MaintenanceLogsUpdated(logs));
    });
  }

  void _onFuelLogsUpdated(FuelLogsUpdated event, Emitter<DashboardState> emit) {
    // Update state with new fuel logs but keep existing maintenance logs
    final newState = state.copyWith(fuelLogs: event.logs);
    _calculateStats(emit, newState);
  }

  void _onMaintenanceLogsUpdated(
      MaintenanceLogsUpdated event, Emitter<DashboardState> emit) {
    // Update state with new maintenance logs but keep existing fuel logs
    final newState = state.copyWith(maintenanceLogs: event.logs);
    _calculateStats(emit, newState);
  }

  void _calculateStats(Emitter<DashboardState> emit, DashboardState currentState) {
    final fuelLogs = currentState.fuelLogs;
    final maintenanceLogs = currentState.maintenanceLogs;

    // 1. Avg Cost / KM
    final avgCost = _statsService.calculateAverageCostPerKm(fuelLogs);
    final fuelEff = _statsService.calculateFuelEfficiency(fuelLogs);

    // 2. Total Fuel Cost
    double totalFuel = 0.0;
    for (var log in fuelLogs) {
      totalFuel += log.cost;
    }

    // 3. Last Service
    double lastServiceCost = 0.0;
    DateTime? lastServiceDate;
    if (maintenanceLogs.isNotEmpty) {
      // Assuming stream returns ordered by date descending
      final last = maintenanceLogs.first;
      lastServiceCost = last.cost;
      lastServiceDate = last.date;
    }

    // 4. Last Refuel
    DateTime? lastRefuelDate;
    if (fuelLogs.isNotEmpty) {
      lastRefuelDate = fuelLogs.first.timestamp;
    }

    // 5. Odometer
    int maxOdo = 0;
    if (fuelLogs.isNotEmpty) {
      maxOdo = fuelLogs.first.odometer; // Sorted descending in repo
    }

    // Check maintenance logs too
    if (maintenanceLogs.isNotEmpty) {
        for (var log in maintenanceLogs) {
            if (log.odometer != null && log.odometer! > maxOdo) {
                maxOdo = log.odometer!;
            }
        }
    }

    // 6. Recent Logs (Mixed)
    List<DashboardLogItem> mixedLogs = [];

    for (var log in fuelLogs) {
      mixedLogs.add(DashboardLogItem(
        id: log.id,
        title: log.stationName ?? 'Refuel',
        subtitle: '${log.liters.toStringAsFixed(1)}L • ${NumberFormat.currency(symbol: _settingsService.currency).format(log.cost / log.liters)}/L',
        amount: log.cost,
        date: log.timestamp,
        type: LogType.fuel,
        originalLog: log,
      ));
    }

    for (var log in maintenanceLogs) {
      mixedLogs.add(DashboardLogItem(
        id: log.id,
        title: log.category,
        subtitle: log.note.isNotEmpty ? log.note : 'Service',
        amount: log.cost,
        date: log.date,
        type: LogType.service,
        originalLog: log,
      ));
    }

    mixedLogs.sort((a, b) => b.date.compareTo(a.date));

    emit(currentState.copyWith(
      status: DashboardStatus.loaded,
      avgCostPerKm: avgCost,
      fuelEfficiency: fuelEff,
      totalFuelCost: totalFuel,
      lastServiceCost: lastServiceCost,
      lastServiceDate: lastServiceDate,
      lastRefuelDate: lastRefuelDate,
      odometer: maxOdo,
      recentLogs: mixedLogs.take(5).toList(),
      allLogs: mixedLogs,
    ));
  }

  @override
  Future<void> close() {
    _fuelSubscription?.cancel();
    _maintenanceSubscription?.cancel();
    return super.close();
  }
}
