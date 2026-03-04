import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/vehicle_model.dart';
import '../../domain/repositories/vehicle_repository.dart';

part 'vehicle_event.dart';
part 'vehicle_state.dart';

@injectable
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository _vehicleRepository;
  StreamSubscription? _vehicleSubscription;

  VehicleBloc(this._vehicleRepository) : super(const VehicleState()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<VehiclesUpdated>(_onVehiclesUpdated);
    on<SelectVehicle>(_onSelectVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
  }

  void _onLoadVehicles(LoadVehicles event, Emitter<VehicleState> emit) {
    emit(state.copyWith(status: VehicleStatus.loading));
    _vehicleSubscription?.cancel();
    _vehicleSubscription = _vehicleRepository.getVehiclesStream().listen((vehicles) {
      add(VehiclesUpdated(vehicles));
    });
  }

  void _onVehiclesUpdated(VehiclesUpdated event, Emitter<VehicleState> emit) {
    final vehicles = event.vehicles;
    VehicleModel? selectedVehicle = state.selectedVehicle;

    if (selectedVehicle == null && vehicles.isNotEmpty) {
      selectedVehicle = vehicles.first;
    } else if (selectedVehicle != null) {
      final exists = vehicles.any((v) => v.id == selectedVehicle!.id);
      if (!exists) {
        selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
      } else {
        selectedVehicle = vehicles.firstWhere((v) => v.id == selectedVehicle!.id);
      }
    }

    emit(state.copyWith(
      status: VehicleStatus.loaded,
      vehicles: vehicles,
      selectedVehicle: selectedVehicle,
    ));
  }

  void _onSelectVehicle(SelectVehicle event, Emitter<VehicleState> emit) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
  }

  Future<void> _onDeleteVehicle(DeleteVehicle event, Emitter<VehicleState> emit) async {
    try {
      await _vehicleRepository.deleteVehicle(event.id);
      // The stream will handle updating the list and removing the selected vehicle if needed.
    } catch (e) {
      emit(state.copyWith(status: VehicleStatus.error));
    }
  }

  @override
  Future<void> close() {
    _vehicleSubscription?.cancel();
    return super.close();
  }
}
