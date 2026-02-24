import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';
import 'expense_log_event.dart';
import 'expense_log_state.dart';

class ExpenseLogBloc extends Bloc<ExpenseLogEvent, ExpenseLogState> {
  final LogRepository _logRepository;

  ExpenseLogBloc(this._logRepository) : super(const ExpenseLogState()) {
    on<SaveExpenseLog>(_onSaveExpenseLog);
  }

  Future<void> _onSaveExpenseLog(SaveExpenseLog event, Emitter<ExpenseLogState> emit) async {
    emit(state.copyWith(status: ExpenseLogStatus.saving));

    try {
      final log = MaintenanceLogModel(
        id: const Uuid().v4(),
        date: event.date,
        category: event.category,
        cost: event.cost,
        note: event.note,
        photoPath: event.photoPath,
        odometer: event.odometer,
      );

      await _logRepository.addMaintenanceLog(log);

      emit(state.copyWith(status: ExpenseLogStatus.saved));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseLogStatus.error,
        errorMessage: 'Failed to save expense: $e',
      ));
    }
  }
}
