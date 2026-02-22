import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

enum QuickLogStatus { initial, cameraReady, capturing, imageCaptured, processing, review, saving, saved, error }

class QuickLogState extends Equatable {
  final QuickLogStatus status;
  final CameraController? cameraController;
  final XFile? imageFile;
  final int? odometer;
  final double? liters;
  final double? cost;
  final String? errorMessage;

  const QuickLogState({
    this.status = QuickLogStatus.initial,
    this.cameraController,
    this.imageFile,
    this.odometer,
    this.liters,
    this.cost,
    this.errorMessage,
  });

  QuickLogState copyWith({
    QuickLogStatus? status,
    CameraController? cameraController,
    XFile? imageFile,
    int? odometer,
    double? liters,
    double? cost,
    String? errorMessage,
  }) {
    return QuickLogState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      imageFile: imageFile ?? this.imageFile,
      odometer: odometer ?? this.odometer,
      liters: liters ?? this.liters,
      cost: cost ?? this.cost,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, cameraController, imageFile, odometer, liters, cost, errorMessage];
}
