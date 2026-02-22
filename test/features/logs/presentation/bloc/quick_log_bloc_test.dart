import 'package:bloc_test/bloc_test.dart';
import 'package:car_care_app/core/services/location_service.dart';
import 'package:car_care_app/core/services/ocr_service.dart';
import 'package:car_care_app/features/logs/data/models/fuel_log_model.dart';
import 'package:car_care_app/features/logs/data/models/location_model.dart';
import 'package:car_care_app/features/logs/domain/repositories/log_repository.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_bloc.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_event.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks
@GenerateMocks([LogRepository, LocationService, OCRService])
import 'quick_log_bloc_test.mocks.dart';

void main() {
  late QuickLogBloc bloc;
  late MockLogRepository mockLogRepository;
  late MockLocationService mockLocationService;
  late MockOCRService mockOCRService;

  setUp(() {
    mockLogRepository = MockLogRepository();
    mockLocationService = MockLocationService();
    mockOCRService = MockOCRService();
    bloc = QuickLogBloc(mockOCRService, mockLocationService, mockLogRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final mockLocation = LocationModel(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
  );

  final mockLog = FuelLogModel(
    id: '1',
    odometer: 1000,
    liters: 10.0,
    cost: 50.0,
    timestamp: DateTime.now(),
    location: mockLocation,
  );

  group('QuickLogBloc Validation', () {
    blocTest<QuickLogBloc, QuickLogState>(
      'emits error when odometer is less than previous log',
      build: () {
        when(mockLogRepository.getRecentFuelLogs()).thenAnswer((_) async => [mockLog]);
        return bloc;
      },
      act: (bloc) => bloc.add(SaveLog(odometer: 900, liters: 10, cost: 50)),
      expect: () => [
        const QuickLogState(status: QuickLogStatus.saving),
        const QuickLogState(
          status: QuickLogStatus.error,
          errorMessage: 'Odometer must be greater than previous log (1000)',
        ),
      ],
      verify: (_) {
        verify(mockLogRepository.getRecentFuelLogs()).called(1);
        verifyNever(mockLogRepository.addFuelLog(any));
      },
    );

    blocTest<QuickLogBloc, QuickLogState>(
      'emits error when odometer is equal to previous log',
      build: () {
        when(mockLogRepository.getRecentFuelLogs()).thenAnswer((_) async => [mockLog]);
        return bloc;
      },
      act: (bloc) => bloc.add(SaveLog(odometer: 1000, liters: 10, cost: 50)),
      expect: () => [
        const QuickLogState(status: QuickLogStatus.saving),
        const QuickLogState(
          status: QuickLogStatus.error,
          errorMessage: 'Odometer must be greater than previous log (1000)',
        ),
      ],
    );

    blocTest<QuickLogBloc, QuickLogState>(
      'saves log when odometer is greater than previous log',
      build: () {
        when(mockLogRepository.getRecentFuelLogs()).thenAnswer((_) async => [mockLog]);
        when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => null); // Mock location
        when(mockLogRepository.addFuelLog(any)).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(SaveLog(odometer: 1100, liters: 10, cost: 50)),
      expect: () => [
        const QuickLogState(status: QuickLogStatus.saving),
        const QuickLogState(status: QuickLogStatus.saved),
      ],
      verify: (_) {
        verify(mockLogRepository.addFuelLog(any)).called(1);
      },
    );

    blocTest<QuickLogBloc, QuickLogState>(
      'saves log when no previous logs exist',
      build: () {
        when(mockLogRepository.getRecentFuelLogs()).thenAnswer((_) async => []);
        when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => null);
        when(mockLogRepository.addFuelLog(any)).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(SaveLog(odometer: 100, liters: 10, cost: 50)),
      expect: () => [
        const QuickLogState(status: QuickLogStatus.saving),
        const QuickLogState(status: QuickLogStatus.saved),
      ],
    );
  });
}
