import '../../data/models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<void> addVehicle(VehicleModel vehicle);
  Future<void> updateVehicle(VehicleModel vehicle);
  Future<void> deleteVehicle(String id);
  Stream<List<VehicleModel>> getVehiclesStream();
}
