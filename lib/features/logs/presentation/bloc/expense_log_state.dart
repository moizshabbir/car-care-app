import 'package:equatable/equatable.dart';

enum ExpenseLogStatus { initial, saving, saved, error }

class ExpenseLogState extends Equatable {
  final ExpenseLogStatus status;
  final String? errorMessage;

  const ExpenseLogState({
    this.status = ExpenseLogStatus.initial,
    this.errorMessage,
  });

  ExpenseLogState copyWith({
    ExpenseLogStatus? status,
    String? errorMessage,
  }) {
    return ExpenseLogState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
