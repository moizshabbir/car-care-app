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
  final String? photoPath;

  const SaveExpenseLog({
    required this.cost,
    required this.category,
    required this.note,
    required this.date,
    this.odometer,
    this.photoPath,
  });

  @override
  List<Object?> get props => [cost, category, note, date, odometer, photoPath];
}
