import 'package:bloc_test/bloc_test.dart';
import 'package:car_care_app/features/logs/presentation/bloc/dashboard_bloc.dart';
import 'package:car_care_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}
class FakeDashboardState extends Fake implements DashboardState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(SubscribeToLogs());
  });

  setUp(() {
    final getIt = GetIt.instance;
    final mockBloc = MockDashboardBloc();

    when(() => mockBloc.state).thenReturn(const DashboardState(status: DashboardStatus.loaded));
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(const DashboardState(status: DashboardStatus.loaded)));
    when(() => mockBloc.close()).thenAnswer((_) async {});
    when(() => mockBloc.add(any())).thenReturn(null);

    if (getIt.isRegistered<DashboardBloc>()) {
      getIt.unregister<DashboardBloc>();
    }
    getIt.registerFactory<DashboardBloc>(() => mockBloc);
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Allow microtasks (Bloc initialization)

    expect(find.text('My Garage'), findsOneWidget);
    expect(find.text('Toyota Camry'), findsOneWidget);
  });
}
