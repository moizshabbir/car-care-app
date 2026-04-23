import 'package:bloc_test/bloc_test.dart';
import 'package:carlog/features/logs/data/models/fuel_log_model.dart';
import 'package:carlog/features/logs/data/models/location_model.dart';
import 'package:carlog/features/logs/data/models/maintenance_log_model.dart';
import 'package:carlog/features/logs/domain/repositories/log_repository.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_event.dart';
import 'package:carlog/features/reports/presentation/bloc/reports_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';


class MockLogRepository extends Mock implements LogRepository {}

void main() {
  late ReportsBloc reportsBloc;
  late MockLogRepository mockLogRepository;

  setUp(() {
    mockLogRepository = MockLogRepository();
    reportsBloc = ReportsBloc(mockLogRepository);
  });

  tearDown(() {
    reportsBloc.close();
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
        latitude: 0,
        longitude: 0,
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
      note: '',
      userId: 'test_user',
    ),
    MaintenanceLogModel(
      id: '2',
      vehicleId: 'v1',
      date: DateTime(2026, 3, 2),
      category: 'Parts',
      cost: 20.0,
      note: 'Oil Filter',
      userId: 'test_user',
    ),
  ];

  group('ReportsBloc', () {
    test('initial state is correct', () {
      expect(reportsBloc.state, const ReportsState());
    });

    blocTest<ReportsBloc, ReportsState>(
      'emits [loading, loaded] when LoadReports is added successfully',
      build: () {
        when(() => mockLogRepository.getRecentFuelLogs())
            .thenAnswer((_) async => tFuelLogs);
        when(() => mockLogRepository.getMaintenanceLogs())
            .thenAnswer((_) async => tMaintenanceLogs);
        return reportsBloc;
      },
      act: (bloc) => bloc.add(LoadReports()),
      expect: () => [
        const ReportsState(status: ReportsStatus.loading),
        ReportsState(
          status: ReportsStatus.loaded,
          fuelLogs: tFuelLogs,
          maintenanceLogs: tMaintenanceLogs,
        ),
      ],
    );

    blocTest<ReportsBloc, ReportsState>(
      'emits [loading, error] when LoadReports fails',
      build: () {
        when(() => mockLogRepository.getRecentFuelLogs())
            .thenThrow(Exception('Failed to load logs'));
        return reportsBloc;
      },
      act: (bloc) => bloc.add(LoadReports()),
      expect: () => [
        const ReportsState(status: ReportsStatus.loading),
        const ReportsState(status: ReportsStatus.error, errorMessage: 'Exception: Failed to load logs'),
      ],
    );
  });
}
