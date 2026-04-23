import 'package:equatable/equatable.dart';

abstract class ExpenseLogEvent extends Equatable {
  const ExpenseLogEvent();

  @override
  List<Object?> get props => [];
}

class SaveExpenseLog extends ExpenseLogEvent {
  final double cost;
  final String category;
  final String note;
  final DateTime date;
  final int? odometer;
  final double? liters;
  final String? photoPath;
  final String? vehicleId;

  const SaveExpenseLog({
    required this.cost,
    required this.category,
    required this.note,
    required this.date,
    this.odometer,
    this.liters,
    this.photoPath,
    this.vehicleId,
  });

  @override
  List<Object?> get props => [cost, category, note, date, odometer, liters, photoPath, vehicleId];
}

class UpdateExpenseLog extends ExpenseLogEvent {
  final String id;
  final double cost;
  final String category;
  final String note;
  final DateTime date;
  final int? odometer;
  final double? liters;
  final String? photoPath;
  final String? vehicleId;

  const UpdateExpenseLog({
    required this.id,
    required this.cost,
    required this.category,
    required this.note,
    required this.date,
    this.odometer,
    this.liters,
    this.photoPath,
    this.vehicleId,
  });

  @override
  List<Object?> get props => [id, cost, category, note, date, odometer, liters, photoPath, vehicleId];
}
