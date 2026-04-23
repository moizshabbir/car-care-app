import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:injectable/injectable.dart';

import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';
import 'expense_log_event.dart';
import 'expense_log_state.dart';

@injectable
class ExpenseLogBloc extends Bloc<ExpenseLogEvent, ExpenseLogState> {
  final LogRepository _logRepository;
  final FirebaseAuth _firebaseAuth;

  ExpenseLogBloc(this._logRepository, this._firebaseAuth) : super(const ExpenseLogState()) {
    on<SaveExpenseLog>(_onSaveExpenseLog);
    on<UpdateExpenseLog>(_onUpdateExpenseLog);
  }

  Future<void> _onSaveExpenseLog(SaveExpenseLog event, Emitter<ExpenseLogState> emit) async {
    emit(state.copyWith(status: ExpenseLogStatus.saving));
    debugPrint("ExpenseLogBloc: Saving expense log (Category: ${event.category})...");

    try {
      final isFuel = event.category.toLowerCase() == 'fuel' || 
                    event.category.toLowerCase() == 'petrol';

      final userId = _firebaseAuth.currentUser?.uid ?? '';

      if (isFuel && event.odometer != null) {
        // Save as FuelLogModel
        final fuelLog = FuelLogModel(
          id: const Uuid().v4(),
          odometer: event.odometer!,
          liters: event.liters ?? 0.0,
          cost: event.cost,
          timestamp: event.date,
          location: null,
          userId: userId,
          vehicleId: event.vehicleId ?? '',
          stationName: event.note.startsWith('From ') ? event.note.replaceFirst('From ', '') : null,
          odometerPhotoPath: event.photoPath,
        );
        await _logRepository.addFuelLog(fuelLog);
      } else {
        // Save as MaintenanceLogModel
        final log = MaintenanceLogModel(
          id: const Uuid().v4(),
          date: event.date,
          category: event.category,
          cost: event.cost,
          note: event.note,
          userId: userId,
          photoPath: event.photoPath,
          odometer: event.odometer,
          vehicleId: event.vehicleId,
        );
        await _logRepository.addMaintenanceLog(log);
      }
      
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

  Future<void> _onUpdateExpenseLog(UpdateExpenseLog event, Emitter<ExpenseLogState> emit) async {
    emit(state.copyWith(status: ExpenseLogStatus.saving));
    debugPrint("ExpenseLogBloc: Updating expense log (ID: ${event.id})...");

    try {
      final isFuel = event.category.toLowerCase() == 'fuel' || 
                    event.category.toLowerCase() == 'petrol';

      final userId = _firebaseAuth.currentUser?.uid ?? '';

      if (isFuel && event.odometer != null) {
        final fuelLog = FuelLogModel(
          id: event.id,
          odometer: event.odometer!,
          liters: event.liters ?? 0.0,
          cost: event.cost,
          timestamp: event.date,
          location: null,
          userId: userId,
          vehicleId: event.vehicleId ?? '',
          stationName: event.note.startsWith('From ') ? event.note.replaceFirst('From ', '') : null,
          odometerPhotoPath: event.photoPath,
        );
        await _logRepository.updateFuelLog(fuelLog);
      } else {
        final log = MaintenanceLogModel(
          id: event.id,
          date: event.date,
          category: event.category,
          cost: event.cost,
          note: event.note,
          userId: userId,
          photoPath: event.photoPath,
          odometer: event.odometer,
          vehicleId: event.vehicleId,
        );
        await _logRepository.updateMaintenanceLog(log);
      }
      
      debugPrint("ExpenseLogBloc: Update successful");
      emit(state.copyWith(status: ExpenseLogStatus.saved));
    } catch (e) {
      debugPrint("ExpenseLogBloc: Update FAILED: $e");
      emit(state.copyWith(
        status: ExpenseLogStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
