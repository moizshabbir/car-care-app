import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
}
