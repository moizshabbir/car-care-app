import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/receipt_parser_service.dart';

enum QuickLogStatus { initial, cameraReady, capturing, imageCaptured, processing, review, odometerCapture, saving, saved, error }

class QuickLogState extends Equatable {
  final QuickLogStatus status;
  final CameraController? cameraController;
  final XFile? imageFile;
  final int? odometer;
  final double? liters;
  final double? cost;
  final String? stationName;
  final String? odometerPhotoPath;
  final ReceiptType? receiptType;
  final List<POSItem>? parsedPOSItems;
  final List<ServiceItem>? parsedServiceItems;
  final String? errorMessage;

  const QuickLogState({
    this.status = QuickLogStatus.initial,
    this.cameraController,
    this.imageFile,
    this.odometer,
    this.liters,
    this.cost,
    this.stationName,
    this.odometerPhotoPath,
    this.receiptType,
    this.parsedPOSItems,
    this.parsedServiceItems,
    this.errorMessage,
  });

  QuickLogState copyWith({
    QuickLogStatus? status,
    CameraController? cameraController,
    XFile? imageFile,
    int? odometer,
    double? liters,
    double? cost,
    String? stationName,
    String? odometerPhotoPath,
    ReceiptType? receiptType,
    List<POSItem>? parsedPOSItems,
    List<ServiceItem>? parsedServiceItems,
    String? errorMessage,
  }) {
    return QuickLogState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      imageFile: imageFile ?? this.imageFile,
      odometer: odometer ?? this.odometer,
      liters: liters ?? this.liters,
      cost: cost ?? this.cost,
      stationName: stationName ?? this.stationName,
      odometerPhotoPath: odometerPhotoPath ?? this.odometerPhotoPath,
      receiptType: receiptType ?? this.receiptType,
      parsedPOSItems: parsedPOSItems ?? this.parsedPOSItems,
      parsedServiceItems: parsedServiceItems ?? this.parsedServiceItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, cameraController, imageFile, odometer, liters, cost,
    stationName, odometerPhotoPath, receiptType, parsedPOSItems, parsedServiceItems, errorMessage];
}
