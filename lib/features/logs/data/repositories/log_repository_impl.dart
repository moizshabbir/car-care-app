import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';

@LazySingleton(as: LogRepository)
class LogRepositoryImpl implements LogRepository {
  final FirebaseFirestore _firestore;

  LogRepositoryImpl(this._firestore);

  @override
  Future<void> addFuelLog(FuelLogModel log) async {
    // 1. Save to Hive (Local)
    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    // Use put to save with key (ID)
    await box.put(log.id, log);

    // 2. Save to Firestore (Remote)
    // Use set with the same ID to keep consistency
    await _firestore.collection('fuel_logs').doc(log.id).set(log.toJson());
  }

  @override
  Future<List<FuelLogModel>> getRecentFuelLogs() async {
    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    List<FuelLogModel> logs = box.values.toList();

    // If local logs are empty, try fetching from Firestore as fallback
    if (logs.isEmpty) {
        try {
            final snapshot = await _firestore.collection('fuel_logs')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .get();

            logs = snapshot.docs.map((doc) => FuelLogModel.fromJson(doc.data())).toList();

            // Save fetched logs to Hive for next time (simple sync)
            for (var log in logs) {
                await box.put(log.id, log);
            }
        } catch (e) {
            // Log error or ignore if offline
            if (kDebugMode) {
              print("Error fetching logs from Firestore: $e");
            }
        }
    }

    logs.sort((a, b) => b.odometer.compareTo(a.odometer));

    return logs.take(5).toList();
  }

  @override
  Future<void> addMaintenanceLog(MaintenanceLogModel log) async {
    // 1. Save to Hive (Local)
    var box = Hive.isBoxOpen('maintenance_logs')
        ? Hive.box<MaintenanceLogModel>('maintenance_logs')
        : await Hive.openBox<MaintenanceLogModel>('maintenance_logs');

    await box.put(log.id, log);

    // 2. Save to Firestore (Remote)
    await _firestore.collection('maintenance_logs').doc(log.id).set(log.toJson());
  }

  @override
  Stream<List<FuelLogModel>> getFuelLogsStream() {
    return _firestore
        .collection('fuel_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FuelLogModel.fromJson(doc.data())).toList();
    });
  }

  @override
  Stream<List<MaintenanceLogModel>> getMaintenanceLogsStream() {
    return _firestore
        .collection('maintenance_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MaintenanceLogModel.fromJson(doc.data()))
          .toList();
    });
  }
}
