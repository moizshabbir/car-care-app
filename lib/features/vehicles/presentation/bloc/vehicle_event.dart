part of 'vehicle_bloc.dart';

abstract class VehicleEvent {}

class LoadVehicles extends VehicleEvent {}

class VehiclesUpdated extends VehicleEvent {
  final List<VehicleModel> vehicles;
  VehiclesUpdated(this.vehicles);
}

class SelectVehicle extends VehicleEvent {
  final VehicleModel vehicle;
  SelectVehicle(this.vehicle);
}

class DeleteVehicle extends VehicleEvent {
  final String id;
  DeleteVehicle(this.id);
}
