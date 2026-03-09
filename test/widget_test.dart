import 'package:bloc_test/bloc_test.dart';
import 'package:car_care_app/features/logs/presentation/bloc/dashboard_bloc.dart';
import 'package:car_care_app/main.dart';
import 'package:car_care_app/features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'package:car_care_app/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:car_care_app/features/vehicles/data/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}

class MockVehicleBloc extends MockBloc<VehicleEvent, VehicleState> implements VehicleBloc {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}
class FakeDashboardState extends Fake implements DashboardState {}

class FakeVehicleEvent extends Fake implements VehicleEvent {}
class FakeVehicleState extends Fake implements VehicleState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(SubscribeToLogs());
    registerFallbackValue(FakeVehicleEvent());
    registerFallbackValue(FakeVehicleState());
  });

  setUp(() {
    final getIt = GetIt.instance;
    final mockBloc = MockDashboardBloc();
    final mockVehicleBloc = MockVehicleBloc();

    when(() => mockBloc.state).thenReturn(const DashboardState(status: DashboardStatus.loaded));
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(const DashboardState(status: DashboardStatus.loaded)));
    when(() => mockBloc.close()).thenAnswer((_) async {});
    when(() => mockBloc.add(any())).thenReturn(null);

    final vState = VehicleState(status: VehicleStatus.loaded, vehicles: [VehicleModel(id: '1', name: 'Toyota Camry', make: 'Toyota', model: 'Camry', year: 2020)], selectedVehicle: VehicleModel(id: '1', name: 'Toyota Camry', make: 'Toyota', model: 'Camry', year: 2020));
    when(() => mockVehicleBloc.state).thenReturn(vState);
    when(() => mockVehicleBloc.stream).thenAnswer((_) => Stream.value(vState));
    when(() => mockVehicleBloc.close()).thenAnswer((_) async {});
    when(() => mockVehicleBloc.add(any())).thenReturn(null);

    if (getIt.isRegistered<DashboardBloc>()) {
      getIt.unregister<DashboardBloc>();
    }
    getIt.registerFactory<DashboardBloc>(() => mockBloc);

    if (getIt.isRegistered<VehicleBloc>()) {
      getIt.unregister<VehicleBloc>();
    }
    getIt.registerFactory<VehicleBloc>(() => mockVehicleBloc);
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Garage'), findsOneWidget);
    expect(find.text('Toyota Camry'), findsOneWidget);
  });
}
