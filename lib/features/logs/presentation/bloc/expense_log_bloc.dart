import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';
import 'expense_log_event.dart';
import 'expense_log_state.dart';

class ExpenseLogBloc extends Bloc<ExpenseLogEvent, ExpenseLogState> {
  final LogRepository _logRepository;
  final FirebaseAuth _firebaseAuth;

  ExpenseLogBloc(this._logRepository, this._firebaseAuth) : super(const ExpenseLogState()) {
    on<SaveExpenseLog>(_onSaveExpenseLog);
  }

  Future<void> _onSaveExpenseLog(SaveExpenseLog event, Emitter<ExpenseLogState> emit) async {
    emit(state.copyWith(status: ExpenseLogStatus.saving));
    debugPrint("ExpenseLogBloc: Saving expense log...");

    final log = MaintenanceLogModel(
      id: const Uuid().v4(),
      date: event.date,
      category: event.category,
      cost: event.cost,
      note: event.note,
      userId: _firebaseAuth.currentUser?.uid ?? '',
      photoPath: event.photoPath,
      odometer: event.odometer,
      vehicleId: event.vehicleId,
    );

    try {
      await _logRepository.addMaintenanceLog(log);
      debugPrint("ExpenseLogBloc: Save successful");
      emit(state.copyWith(status: ExpenseLogStatus.saved));
    } catch (e) {
      debugPrint("ExpenseLogBloc: Save FAILED: $e");
      emit(state.copyWith(
        status: ExpenseLogStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
