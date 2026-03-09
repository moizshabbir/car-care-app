import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

@LazySingleton(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  final FirebaseFirestore _firestore;

  VehicleRepositoryImpl(this._firestore);

  @override
  Future<void> addVehicle(VehicleModel vehicle) async {
    var box = Hive.isBoxOpen('vehicles')
        ? Hive.box<VehicleModel>('vehicles')
        : await Hive.openBox<VehicleModel>('vehicles');

    await box.put(vehicle.id, vehicle);

    await _firestore.collection('vehicles').doc(vehicle.id).set(vehicle.toJson());
  }

  @override
  Future<void> updateVehicle(VehicleModel vehicle) async {
    var box = Hive.isBoxOpen('vehicles')
        ? Hive.box<VehicleModel>('vehicles')
        : await Hive.openBox<VehicleModel>('vehicles');

    await box.put(vehicle.id, vehicle);

    await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toJson());
  }

  @override
  Future<void> deleteVehicle(String id) async {
    var box = Hive.isBoxOpen('vehicles')
        ? Hive.box<VehicleModel>('vehicles')
        : await Hive.openBox<VehicleModel>('vehicles');

    await box.delete(id);

    await _firestore.collection('vehicles').doc(id).delete();
  }

  @override
  Stream<List<VehicleModel>> getVehiclesStream() {
    return _firestore
        .collection('vehicles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VehicleModel.fromJson(doc.data())).toList();
    });
  }
}
