import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/ocr_service.dart';
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

  QuickLogBloc(
    this._ocrService,
    this._locationService,
    this._logRepository,
  ) : super(const QuickLogState()) {
    on<StartCamera>(_onStartCamera);
    on<CaptureImage>(_onCaptureImage);
    on<RetakeImage>(_onRetakeImage);
    on<ProcessImage>(_onProcessImage);
    on<SwitchToManual>(_onSwitchToManual);
    on<UpdateLogData>(_onUpdateLogData);
    on<SaveLog>(_onSaveLog);
  }

  Future<void> _onStartCamera(StartCamera event, Emitter<QuickLogState> emit) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(state.copyWith(
          status: QuickLogStatus.error,
          errorMessage: 'No cameras available',
        ));
        return;
      }
      // Use the first camera (usually back camera)
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      emit(state.copyWith(
        status: QuickLogStatus.cameraReady,
        cameraController: controller,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to initialize camera: $e',
      ));
    }
  }

  Future<void> _onCaptureImage(CaptureImage event, Emitter<QuickLogState> emit) async {
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
      return;
    }

    emit(state.copyWith(status: QuickLogStatus.capturing));

    try {
      final file = await state.cameraController!.takePicture();
      emit(state.copyWith(
        status: QuickLogStatus.imageCaptured,
        imageFile: file,
      ));
      add(ProcessImage());
    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'Failed to capture image: $e',
      ));
    }
  }

  Future<void> _onRetakeImage(RetakeImage event, Emitter<QuickLogState> emit) async {
    // Reset data but keep camera controller
    // Using constructor to reset fields to null
    emit(QuickLogState(
      status: QuickLogStatus.cameraReady,
      cameraController: state.cameraController,
      // imageFile, odometer, etc. will be null
    ));
  }

  Future<void> _onProcessImage(ProcessImage event, Emitter<QuickLogState> emit) async {
    if (state.imageFile == null) return;

    emit(state.copyWith(status: QuickLogStatus.processing));

    try {
      final inputImage = InputImage.fromFilePath(state.imageFile!.path);
      final recognizedText = await _ocrService.processImage(inputImage);

      // Simple heuristic to extract numbers
      final text = recognizedText.text;

      int? foundOdometer;
      double? foundLiters;
      double? foundCost;

      // Regex for finding numbers (integer or float)
      final RegExp numberRegExp = RegExp(r"(\d+(\.\d+)?)");
      final matches = numberRegExp.allMatches(text);

      List<double> numbers = [];
      for (final match in matches) {
        final val = double.tryParse(match.group(0)!);
        if (val != null) {
          numbers.add(val);
        }
      }

      // Sort numbers descending to prioritize larger numbers (likely Odometer/Cost)
      numbers.sort((a, b) => b.compareTo(a));

      // Very basic heuristic assignment
      for (final num in numbers) {
        if (num > 1000 && num % 1 == 0 && foundOdometer == null) {
          foundOdometer = num.toInt();
        } else if (foundCost == null) {
           foundCost = num;
        } else if (foundLiters == null) {
          foundLiters = num;
        }
      }

      emit(state.copyWith(
        status: QuickLogStatus.review,
        odometer: foundOdometer,
        liters: foundLiters,
        cost: foundCost,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: QuickLogStatus.error,
        errorMessage: 'OCR Processing failed: $e',
      ));
    }
  }

  Future<void> _onSwitchToManual(SwitchToManual event, Emitter<QuickLogState> emit) async {
     emit(state.copyWith(status: QuickLogStatus.review));
  }

  Future<void> _onUpdateLogData(UpdateLogData event, Emitter<QuickLogState> emit) async {
    // Only update fields that are provided (not null)
    // Wait, if I want to clear a field, I can't pass null.
    // But UI usually sends the current value.
    // For now, assume UI handles state.

    // Actually, copyWith merges.
    // So if event.odometer is null, it keeps old value.
    // That's fine for partial updates.
    emit(state.copyWith(
      odometer: event.odometer,
      liters: event.liters,
      cost: event.cost,
    ));
  }

  Future<void> _onSaveLog(SaveLog event, Emitter<QuickLogState> emit) async {
    emit(state.copyWith(status: QuickLogStatus.saving));

    try {
      // Get location
      final position = await _locationService.getCurrentLocation();

      final location = LocationModel(
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        timestamp: DateTime.now(),
      );

      final log = FuelLogModel(
        id: const Uuid().v4(),
        odometer: event.odometer,
        liters: event.liters,
        cost: event.cost,
        timestamp: DateTime.now(),
        location: location,
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
