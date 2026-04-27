import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:carlog/features/logs/data/models/fuel_log_model.dart';
import 'package:carlog/features/logs/data/models/location_model.dart';
import 'package:carlog/features/logs/data/models/maintenance_log_model.dart';
import 'package:carlog/features/logs/domain/repositories/log_repository.dart';
import 'package:carlog/features/logs/presentation/bloc/dashboard_bloc.dart';
import 'package:carlog/core/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLogRepository extends Mock implements LogRepository {}
class MockSettingsService extends Mock implements SettingsService {}

void main() {
  late DashboardBloc dashboardBloc;
  late MockLogRepository mockLogRepository;
  late MockSettingsService mockSettingsService;

  setUp(() {
    mockLogRepository = MockLogRepository();
    mockSettingsService = MockSettingsService();
    
    when(() => mockSettingsService.currency).thenReturn(r'$');
    
    dashboardBloc = DashboardBloc(mockLogRepository, mockSettingsService);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  final tFuelLogs = [
    FuelLogModel(
      id: '1',
      vehicleId: 'v1',
      odometer: 1000,
      liters: 10.0,
      cost: 100.0,
      timestamp: DateTime(2026, 3, 1),
      location: LocationModel(
        latitude: 10.0,
        longitude: 10.0,
        timestamp: DateTime(2026, 3, 1),
      ),
      userId: 'test_user',
    ),
  ];

  final tMaintenanceLogs = [
    MaintenanceLogModel(
      id: '1',
      vehicleId: 'v1',
      date: DateTime(2026, 3, 1),
      category: 'Service',
      cost: 50.0,
      note: "",
      userId: 'test_user',
    ),
  ];

  group('DashboardBloc', () {
    test('initial state is correct', () {
      expect(dashboardBloc.state, const DashboardState());
    });

    blocTest<DashboardBloc, DashboardState>(
      'subscribes to fuel and maintenance streams when SubscribeToLogs is added',
      build: () {
        when(() => mockLogRepository.getFuelLogsStream(any()))
            .thenAnswer((_) => Stream.value(tFuelLogs));
        when(() => mockLogRepository.getMaintenanceLogsStream(any()))
            .thenAnswer((_) => Stream.value(tMaintenanceLogs));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(SubscribeToLogs(vehicleId: 'v1')),
      expect: () => [
        const DashboardState(status: DashboardStatus.loading),
        isA<DashboardState>().having((s) => s.status, 'status', DashboardStatus.loaded),
        isA<DashboardState>().having((s) => s.status, 'status', DashboardStatus.loaded),
      ],
      verify: (_) {
        verify(() => mockLogRepository.getFuelLogsStream('v1')).called(1);
        verify(() => mockLogRepository.getMaintenanceLogsStream('v1')).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'updates stats when FuelLogsUpdated is added',
      build: () => dashboardBloc,
      act: (bloc) => bloc.add(FuelLogsUpdated(tFuelLogs)),
      expect: () => [
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loaded)
            .having((s) => s.fuelLogs, 'fuelLogs', tFuelLogs)
            .having((s) => s.totalFuelCost, 'totalFuelCost', 100.0)
            .having((s) => s.odometer, 'odometer', 1000),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'updates stats when MaintenanceLogsUpdated is added',
      build: () => dashboardBloc,
      act: (bloc) => bloc.add(MaintenanceLogsUpdated(tMaintenanceLogs)),
      expect: () => [
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loaded)
            .having((s) => s.maintenanceLogs, 'maintenanceLogs', tMaintenanceLogs)
            .having((s) => s.lastServiceCost, 'lastServiceCost', 50.0),
      ],
    );
  });
}
