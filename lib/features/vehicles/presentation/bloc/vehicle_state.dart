part of 'vehicle_bloc.dart';

enum VehicleStatus { initial, loading, loaded, error }

class VehicleState {
  final VehicleStatus status;
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;

  const VehicleState({
    this.status = VehicleStatus.initial,
    this.vehicles = const [],
    this.selectedVehicle,
  });

  VehicleState copyWith({
    VehicleStatus? status,
    List<VehicleModel>? vehicles,
    VehicleModel? selectedVehicle,
  }) {
    return VehicleState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
    );
  }
}
