import 'package:bloc_test/bloc_test.dart';
import 'package:carlog/features/logs/data/models/maintenance_log_model.dart';
import 'package:carlog/features/logs/domain/repositories/log_repository.dart';
import 'package:carlog/features/logs/presentation/bloc/expense_log_bloc.dart';
import 'package:carlog/features/logs/presentation/bloc/expense_log_event.dart';
import 'package:carlog/features/logs/presentation/bloc/expense_log_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLogRepository extends Mock implements LogRepository {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late ExpenseLogBloc expenseLogBloc;
  late MockLogRepository mockLogRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockLogRepository = MockLogRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_user_id');

    expenseLogBloc = ExpenseLogBloc(mockLogRepository, mockFirebaseAuth);
    
    registerFallbackValue(FakeMaintenanceLogModel());
  });

  tearDown(() {
    expenseLogBloc.close();
  });

  group('ExpenseLogBloc', () {
    test('initial state is correct', () {
      expect(expenseLogBloc.state, const ExpenseLogState());
    });

    blocTest<ExpenseLogBloc, ExpenseLogState>(
      'emits [saving, saved] when SaveExpenseLog is added successfully',
      build: () {
        when(() => mockLogRepository.addMaintenanceLog(any()))
            .thenAnswer((_) async => {});
        return expenseLogBloc;
      },
      act: (bloc) => bloc.add(SaveExpenseLog(
        cost: 100.0,
        category: 'Service',
        note: 'Oil Change',
        date: DateTime(2026, 3, 1),
        vehicleId: 'v1',
      )),
      expect: () => [
        const ExpenseLogState(status: ExpenseLogStatus.saving),
        const ExpenseLogState(status: ExpenseLogStatus.saved),
      ],
      verify: (_) {
        verify(() => mockLogRepository.addMaintenanceLog(any())).called(1);
      },
    );

    blocTest<ExpenseLogBloc, ExpenseLogState>(
      'emits [saving, error] when SaveExpenseLog fails',
      build: () {
        when(() => mockLogRepository.addMaintenanceLog(any()))
            .thenThrow(Exception('Save failed'));
        return expenseLogBloc;
      },
      act: (bloc) => bloc.add(SaveExpenseLog(
        cost: 100.0,
        category: 'Service',
        note: 'Oil Change',
        date: DateTime(2026, 3, 1),
        vehicleId: 'v1',
      )),
      expect: () => [
        const ExpenseLogState(status: ExpenseLogStatus.saving),
        isA<ExpenseLogState>().having((s) => s.status, 'status', ExpenseLogStatus.error),
      ],
    );

    blocTest<ExpenseLogBloc, ExpenseLogState>(
      'emits [saving, saved] when UpdateExpenseLog is added successfully',
      build: () {
        when(() => mockLogRepository.updateMaintenanceLog(any()))
            .thenAnswer((_) async => {});
        return expenseLogBloc;
      },
      act: (bloc) => bloc.add(UpdateExpenseLog(
        id: '123',
        cost: 150.0,
        category: 'Service',
        note: 'Oil Change Updated',
        date: DateTime(2026, 3, 1),
        vehicleId: 'v1',
      )),
      expect: () => [
        const ExpenseLogState(status: ExpenseLogStatus.saving),
        const ExpenseLogState(status: ExpenseLogStatus.saved),
      ],
      verify: (_) {
        verify(() => mockLogRepository.updateMaintenanceLog(any())).called(1);
      },
    );
  });
}

class FakeMaintenanceLogModel extends Fake implements MaintenanceLogModel {}
