import 'package:flutter/foundation.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:carlog/features/logs/presentation/bloc/dashboard_bloc.dart';
import 'package:carlog/main.dart';
import 'package:carlog/features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'package:carlog/features/vehicles/data/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carlog/core/services/settings_service.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_event.dart';
import 'package:carlog/features/auth/presentation/bloc/auth_state.dart';

class MockSettingsService extends Mock implements SettingsService {
  @override
  void addListener(VoidCallback? listener) {}
  @override
  void removeListener(VoidCallback? listener) {}
  @override
  bool get hasListeners => false;
}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockVehicleBloc extends MockBloc<VehicleEvent, VehicleState> implements VehicleBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}
class FakeDashboardState extends Fake implements DashboardState {}
class FakeVehicleEvent extends Fake implements VehicleEvent {}
class FakeVehicleState extends Fake implements VehicleState {}
class FakeAuthEvent extends Fake implements AuthEvent {}
class FakeAuthState extends Fake implements AuthState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(SubscribeToLogs());
    registerFallbackValue(FakeVehicleEvent());
    registerFallbackValue(FakeVehicleState());
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
  });

  setUp(() {
    final getIt = GetIt.instance;
    final mockBloc = MockDashboardBloc();
    final mockVehicleBloc = MockVehicleBloc();
    final mockAuthBloc = MockAuthBloc();
    final mockSettingsService = MockSettingsService();

    when(() => mockSettingsService.currency).thenReturn(r'$');
    when(() => mockSettingsService.dateFormat).thenReturn('dd/MM/yyyy');

    when(() => mockBloc.state).thenReturn(const DashboardState(status: DashboardStatus.loaded));
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(const DashboardState(status: DashboardStatus.loaded)));
    when(() => mockBloc.close()).thenAnswer((_) async {});
    when(() => mockBloc.add(any())).thenReturn(null);

    final vState = VehicleState(
      status: VehicleStatus.loaded,
      vehicles: [
        VehicleModel(
          id: '1',
          name: 'Toyota Camry',
          make: 'Toyota',
          model: 'Camry',
          year: 2020,
          userId: 'test_user',
        )
      ],
      selectedVehicle: VehicleModel(
        id: '1',
        name: 'Toyota Camry',
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        userId: 'test_user',
      ),
    );
    when(() => mockVehicleBloc.state).thenReturn(vState);
    when(() => mockVehicleBloc.stream).thenAnswer((_) => Stream.value(vState));
    when(() => mockVehicleBloc.close()).thenAnswer((_) async {});
    when(() => mockVehicleBloc.add(any())).thenReturn(null);

    final aState = AuthState(status: AuthStatus.authenticated);
    when(() => mockAuthBloc.state).thenReturn(aState);
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(aState));
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.add(any())).thenReturn(null);

    if (getIt.isRegistered<DashboardBloc>()) {
      getIt.unregister<DashboardBloc>();
    }
    getIt.registerFactory<DashboardBloc>(() => mockBloc);

    if (getIt.isRegistered<VehicleBloc>()) {
      getIt.unregister<VehicleBloc>();
    }
    getIt.registerFactory<VehicleBloc>(() => mockVehicleBloc);

    if (getIt.isRegistered<AuthBloc>()) {
      getIt.unregister<AuthBloc>();
    }
    getIt.registerFactory<AuthBloc>(() => mockAuthBloc);

    if (getIt.isRegistered<SettingsService>()) {
      getIt.unregister<SettingsService>();
    }
    getIt.registerSingleton<SettingsService>(mockSettingsService);
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Garage'), findsOneWidget);
    expect(find.textContaining('Toyota Camry'), findsWidgets);
  });
}
