import 'package:bloc_test/bloc_test.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_bloc.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_event.dart';
import 'package:car_care_app/core/services/analytics_service.dart';
import 'package:car_care_app/features/logs/presentation/bloc/quick_log_state.dart';
import 'package:car_care_app/features/logs/presentation/pages/quick_log_page.dart';
import 'package:car_care_app/features/logs/presentation/widgets/fuel_log_manual_entry_sheet.dart';
import 'package:car_care_app/features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'package:car_care_app/features/vehicles/data/models/vehicle_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockQuickLogBloc extends MockBloc<QuickLogEvent, QuickLogState> implements QuickLogBloc {}
class MockVehicleBloc extends MockBloc<VehicleEvent, VehicleState> implements VehicleBloc {}

class FakeQuickLogEvent extends Fake implements QuickLogEvent {}

class MockAnalyticsService extends Mock implements AnalyticsService {}
class FakeVehicleEvent extends Fake implements VehicleEvent {}

void main() {
  late MockQuickLogBloc mockBloc;
  late MockAnalyticsService mockAnalytics;
  late MockVehicleBloc mockVehicleBloc;

  setUpAll(() {
    registerFallbackValue(FakeQuickLogEvent());
    registerFallbackValue(StartCamera());
    registerFallbackValue(FakeVehicleEvent());
  });

  setUp(() {
    mockBloc = MockQuickLogBloc();
    mockAnalytics = MockAnalyticsService();
    mockVehicleBloc = MockVehicleBloc();

    when(() => mockAnalytics.logLogStart()).thenAnswer((_) async {});
    when(() => mockAnalytics.startTimer(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.stopTimer(any())).thenAnswer((_) async {});

    // Use Stream.value to provide initial state, preventing hangs
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(const QuickLogState()));
    when(() => mockBloc.state).thenReturn(const QuickLogState());
    when(() => mockBloc.close()).thenAnswer((_) async {});
    when(() => mockBloc.add(any())).thenReturn(null);

    final getIt = GetIt.instance;
    if (getIt.isRegistered<QuickLogBloc>()) {
      getIt.unregister<QuickLogBloc>();
    }
    getIt.registerFactory<QuickLogBloc>(() => mockBloc);

    when(() => mockVehicleBloc.state).thenReturn(const VehicleState(status: VehicleStatus.loaded, vehicles: []));
    when(() => mockVehicleBloc.stream).thenAnswer((_) => Stream.value(const VehicleState(status: VehicleStatus.loaded, vehicles: [])));
    when(() => mockVehicleBloc.close()).thenAnswer((_) async {});
    when(() => mockVehicleBloc.add(any())).thenReturn(null);

    if (getIt.isRegistered<AnalyticsService>()) {
      getIt.unregister<AnalyticsService>();
    }
    getIt.registerSingleton<AnalyticsService>(mockAnalytics);

    if (getIt.isRegistered<VehicleBloc>()) {
      getIt.unregister<VehicleBloc>();
    }
    getIt.registerFactory<VehicleBloc>(() => mockVehicleBloc);
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<VehicleBloc>.value(
      value: mockVehicleBloc,
      child: const MaterialApp(
        home: QuickLogPage(),
      ),
    );
  }

  testWidgets('QuickLogPage displays error when camera permission denied or error occurs', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const QuickLogState(status: QuickLogStatus.error, errorMessage: 'Camera permission denied'),
    );
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(
      const QuickLogState(status: QuickLogStatus.error, errorMessage: 'Camera permission denied'),
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Error: Camera permission denied'), findsOneWidget);
  });

  testWidgets('QuickLogPage shows ManualEntryForm when status is review', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const QuickLogState(status: QuickLogStatus.review),
    );
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(
      const QuickLogState(status: QuickLogStatus.review),
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(FuelLogManualEntrySheet), findsOneWidget);
    expect(find.text('ODOMETER READING'), findsOneWidget);
  });

  testWidgets('QuickLogPage shows loading indicator when status is processing and camera not ready', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const QuickLogState(status: QuickLogStatus.processing),
    );
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(
      const QuickLogState(status: QuickLogStatus.processing),
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
