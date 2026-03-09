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

class PickImageFromGallery extends QuickLogEvent {}

class PickDocument extends QuickLogEvent {}

class SwitchToManual extends QuickLogEvent {}

class CaptureOdometerPhoto extends QuickLogEvent {}

class UpdateLogData extends QuickLogEvent {
  final int? odometer;
  final double? liters;
  final double? cost;
  final String? stationName;

  const UpdateLogData({this.odometer, this.liters, this.cost, this.stationName});

  @override
  List<Object?> get props => [odometer, liters, cost, stationName];
}

class SaveLog extends QuickLogEvent {
  final int odometer;
  final double liters;
  final double cost;
  final String? vehicleId;
  final String? stationName;
  final String? odometerPhotoPath;

  const SaveLog({
    required this.odometer,
    required this.liters,
    required this.cost,
    this.vehicleId,
    this.stationName,
    this.odometerPhotoPath,
  });

  @override
  List<Object?> get props => [odometer, liters, cost, vehicleId, stationName, odometerPhotoPath];
}
