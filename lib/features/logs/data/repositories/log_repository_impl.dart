import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fuel_log_model.dart';
import '../../domain/repositories/log_repository.dart';

@LazySingleton(as: LogRepository)
class LogRepositoryImpl implements LogRepository {
  final FirebaseFirestore _firestore;

  LogRepositoryImpl(this._firestore);

  @override
  Future<void> addFuelLog(FuelLogModel log) async {
    // 1. Save to Hive (Local)
    // Ideally, Hive boxes should be opened at app start.
    // We check if open, otherwise open it.
    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    // Use put to save with key (ID)
    await box.put(log.id, log);

    // 2. Save to Firestore (Remote)
    // Use set with the same ID to keep consistency
    await _firestore.collection('fuel_logs').doc(log.id).set(log.toJson());
  }
}
