import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/receipt_parser_service.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/location_model.dart';
import '../../domain/repositories/log_repository.dart';
import 'quick_log_event.dart';
import 'quick_log_state.dart';

@injectable
class QuickLogBloc extends Bloc<QuickLogEvent, QuickLogState> {
  final OCRService _ocrService;
  final LocationService _locationService;
  final LogRepository _logRepository;
  final ReceiptParserService _receiptParserService;
  final FirebaseAuth _firebaseAuth;

  QuickLogBloc(
    this._ocrService,
    this._locationService,
    this._logRepository,
    this._receiptParserService,
    this._firebaseAuth,
  ) : super(const QuickLogState()) {
    on<StartCamera>(_onStartCamera);
    on<CaptureImage>(_onCaptureImage);
    on<RetakeImage>(_onRetakeImage);
    on<ProcessImage>(_onProcessImage);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<PickDocument>(_onPickDocument);
    on<SwitchToManual>(_onSwitchToManual);
    on<CaptureOdometerPhoto>(_onCaptureOdometerPhoto);
    on<UpdateLogData>(_onUpdateLogData);
    on<SaveLog>(_onSaveLog);
  }

  Future<void> _onStartCamera(StartCamera event, Emitter<QuickLogState> emit) async {
    // Just reset the state to ready when starting
    emit(state.copyWith(
      status: QuickLogStatus.cameraReady,
    ));
  }

  Future<void> _onCaptureImage(CaptureImage event, Emitter<QuickLogState> emit) async {
    emit(state.copyWith(status: QuickLogStatus.capturing));

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        emit(state.copyWith(
          status: QuickLogStatus.imageCaptured,
          imageFile: XFile(pickedFile.path),
        ));
        add(ProcessImage());
      } else {
        // User cancelled camera
        emit(state.copyWith(status: QuickLogStatus.cameraReady));
      }
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to capture image: $e',
      ));
    }
  }

  Future<void> _onPickImageFromGallery(PickImageFromGallery event, Emitter<QuickLogState> emit) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        emit(state.copyWith(
          status: QuickLogStatus.imageCaptured,
          imageFile: XFile(pickedFile.path),
        ));
        add(ProcessImage());
      }
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to pick image from gallery: $e',
      ));
    }
  }

  Future<void> _onPickDocument(PickDocument event, Emitter<QuickLogState> emit) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        emit(state.copyWith(
          status: QuickLogStatus.imageCaptured,
          imageFile: XFile(result.files.single.path!),
        ));
        add(ProcessImage());
      }
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to pick document: $e',
      ));
    }
  }

  Future<void> _onRetakeImage(RetakeImage event, Emitter<QuickLogState> emit) async {
    // Reset data
    emit(const QuickLogState(
      status: QuickLogStatus.cameraReady,
    ));
  }

  Future<void> _onProcessImage(ProcessImage event, Emitter<QuickLogState> emit) async {
    if (state.imageFile == null) {
      debugPrint('QUICK_LOG_BLOC: No image file to process');
      return;
    }

    emit(state.copyWith(status: QuickLogStatus.processing));
    debugPrint('QUICK_LOG_BLOC: Status -> Processing. Path: ${state.imageFile!.path}');

    try {
      final dynamic parsed = await _receiptParserService.parseAnyReceipt(state.imageFile!.path, typeHint: ReceiptType.fuel);
      debugPrint('QUICK_LOG_BLOC: Result from Parser: ${parsed?.runtimeType}');

      if (parsed is ParsedFuelReceipt) {
        debugPrint('QUICK_LOG_BLOC: Mapped Fuel Receipt - Amount: ${parsed.totalAmount}, Liters: ${parsed.liters}, Odo: ${parsed.odometer}');
        emit(state.copyWith(
          status: QuickLogStatus.review,
          receiptType: ReceiptType.fuel,
          stationName: parsed.stationName,
          cost: parsed.totalAmount,
          liters: parsed.liters,
          odometer: parsed.odometer?.toInt(),
          scannedCurrency: parsed.currency,
        ));
      } else if (parsed is ParsedPOSReceipt) {
        debugPrint('QUICK_LOG_BLOC: Mapped POS Receipt - Amount: ${parsed.totalAmount}, Odo: ${parsed.odometer}');
        emit(state.copyWith(
          status: QuickLogStatus.review,
          receiptType: ReceiptType.pos,
          stationName: parsed.storeName,
          parsedPOSItems: parsed.items,
          cost: parsed.totalAmount,
          odometer: parsed.odometer?.toInt(),
          scannedCurrency: parsed.currency,
        ));
      } else if (parsed is ParsedMechanicBill) {
        debugPrint('QUICK_LOG_BLOC: Mapped Mechanic Bill - Amount: ${parsed.totalAmount}, Odo: ${parsed.odometer}');
        emit(state.copyWith(
          status: QuickLogStatus.review,
          receiptType: ReceiptType.mechanic,
          stationName: parsed.mechanicName,
          parsedServiceItems: parsed.services,
          cost: parsed.totalAmount,
          odometer: parsed.odometer?.toInt(),
          scannedCurrency: parsed.currency,
        ));
      } else {
        // Fallback or Unknown
        debugPrint('QUICK_LOG_BLOC: Could not categorize based on parser result.');
        emit(state.copyWith(
          status: QuickLogStatus.error,
          errorMessage: 'Could not categorize the receipt from the image.',
        ));
      }
    } catch (e) {
      debugPrint('QUICK_LOG_BLOC Error: $e');
      final message = e is AIException ? e.message : 'AI Processing failed: $e';
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onCaptureOdometerPhoto(CaptureOdometerPhoto event, Emitter<QuickLogState> emit) async {
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
      return;
    }

    emit(state.copyWith(status: QuickLogStatus.capturing));

    try {
      final file = await state.cameraController!.takePicture();

      // OCR the odometer photo
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizedText = await _ocrService.processImage(inputImage);
      final text = recognizedText.text;

      // Extract odometer reading — look for the largest number
      final RegExp numberRegExp = RegExp(r'(\d+)');
      final matches = numberRegExp.allMatches(text);
      int? foundOdometer;

      List<int> numbers = [];
      for (final match in matches) {
        final val = int.tryParse(match.group(0)!);
        if (val != null && val > 100) {
          numbers.add(val);
        }
      }

      if (numbers.isNotEmpty) {
        numbers.sort((a, b) => b.compareTo(a));
        foundOdometer = numbers.first;
      }

      emit(state.copyWith(
        status: QuickLogStatus.review,
        odometerPhotoPath: file.path,
        odometer: foundOdometer,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to capture odometer: $e',
      ));
    }
  }

  Future<void> _onSwitchToManual(SwitchToManual event, Emitter<QuickLogState> emit) async {
     emit(state.copyWith(status: QuickLogStatus.review));
  }

  Future<void> _onUpdateLogData(UpdateLogData event, Emitter<QuickLogState> emit) async {
    emit(state.copyWith(
      odometer: event.odometer,
      liters: event.liters,
      cost: event.cost,
      stationName: event.stationName,
    ));
  }

  Future<void> _onSaveLog(SaveLog event, Emitter<QuickLogState> emit) async {
    emit(state.copyWith(status: QuickLogStatus.saving));

    try {
      final recentLogs = await _logRepository.getRecentFuelLogs();
      if (recentLogs.isNotEmpty) {
        final lastLog = recentLogs.first;
        if (event.odometer <= lastLog.odometer) {
          emit(state.copyWith(
            status: QuickLogStatus.error,
            errorMessage: 'Odometer must be greater than previous log (${lastLog.odometer})',
          ));
          return;
        }
      }

      // Get location
      final position = await _locationService.getCurrentLocation();

      final location = position != null
          ? LocationModel(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now(),
            )
          : null;

      final log = FuelLogModel(
        id: const Uuid().v4(),
        odometer: event.odometer,
        liters: event.liters,
        cost: event.cost,
        timestamp: DateTime.now(),
        location: location,
        userId: _firebaseAuth.currentUser?.uid ?? '',
        vehicleId: event.vehicleId,
        stationName: event.stationName,
        odometerPhotoPath: event.odometerPhotoPath,
      );

      await _logRepository.addFuelLog(log);

      emit(state.copyWith(status: QuickLogStatus.saved));

    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to save log: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    state.cameraController?.dispose();
    return super.close();
  }
}
