import 'package:equatable/equatable.dart';

abstract class QuickLogEvent extends Equatable {
  const QuickLogEvent();

  @override
  List<Object?> get props => [];
}

class StartCamera extends QuickLogEvent {}

class CaptureImage extends QuickLogEvent {}

class RetakeImage extends QuickLogEvent {}

class ProcessImage extends QuickLogEvent {}

class SwitchToManual extends QuickLogEvent {}

class UpdateLogData extends QuickLogEvent {
  final int? odometer;
  final double? liters;
  final double? cost;

  const UpdateLogData({this.odometer, this.liters, this.cost});

  @override
  List<Object?> get props => [odometer, liters, cost];
}

class SaveLog extends QuickLogEvent {
  final int odometer;
  final double liters;
  final double cost;

  const SaveLog({required this.odometer, required this.liters, required this.cost});

  @override
  List<Object?> get props => [odometer, liters, cost];
}
