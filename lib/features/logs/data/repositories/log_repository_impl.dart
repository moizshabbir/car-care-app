import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';

@LazySingleton(as: LogRepository)
class LogRepositoryImpl implements LogRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  LogRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<void> addFuelLog(FuelLogModel log) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    final logWithUserId = FuelLogModel(
      id: log.id,
      odometer: log.odometer,
      liters: log.liters,
      cost: log.cost,
      timestamp: log.timestamp,
      location: log.location,
      userId: userId,
      vehicleId: log.vehicleId,
      stationName: log.stationName,
      odometerPhotoPath: log.odometerPhotoPath,
    );

    // 1. Save to Hive (Local)
    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    await box.put(logWithUserId.id, logWithUserId);

    // 2. Save to Firestore (Remote)
    await _firestore.collection('fuel_logs').doc(logWithUserId.id).set(logWithUserId.toJson());
  }

  @override
  Future<List<FuelLogModel>> getRecentFuelLogs() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return [];

    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    List<FuelLogModel> logs = box.values.where((log) => log.userId == userId).toList();

    // If local logs are empty, try fetching from Firestore as fallback
    if (logs.isEmpty) {
      try {
        final snapshot = await _firestore
            .collection('fuel_logs')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        logs = snapshot.docs.map((doc) => FuelLogModel.fromJson(doc.data())).toList();

        // Save fetched logs to Hive for next time
        for (var log in logs) {
          await box.put(log.id, log);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching logs from Firestore: $e");
        }
      }
    }

    logs.sort((a, b) => b.odometer.compareTo(a.odometer));
    return logs.take(5).toList();
  }

  @override
  Future<List<FuelLogModel>> getAllFuelLogs() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return [];

    var box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    List<FuelLogModel> logs = box.values.where((log) => log.userId == userId).toList();

    if (logs.isEmpty) {
      try {
        final snapshot = await _firestore
            .collection('fuel_logs')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        logs = snapshot.docs.map((doc) => FuelLogModel.fromJson(doc.data())).toList();

        for (var log in logs) {
          await box.put(log.id, log);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching all fuel logs from Firestore: $e");
        }
      }
    }

    logs.sort((a, b) => b.odometer.compareTo(a.odometer));
    return logs;
  }

  @override
  Future<void> addMaintenanceLog(MaintenanceLogModel log) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    final logWithUserId = MaintenanceLogModel(
      id: log.id,
      date: log.date,
      category: log.category,
      cost: log.cost,
      note: log.note,
      userId: userId,
      photoPath: log.photoPath,
      odometer: log.odometer,
      vehicleId: log.vehicleId,
    );

    // 1. Save to Hive (Local)
    var box = Hive.isBoxOpen('maintenance_logs')
        ? Hive.box<MaintenanceLogModel>('maintenance_logs')
        : await Hive.openBox<MaintenanceLogModel>('maintenance_logs');

    await box.put(logWithUserId.id, logWithUserId);

    // 2. Save to Firestore (Remote)
    await _firestore
        .collection('maintenance_logs')
        .doc(logWithUserId.id)
        .set(logWithUserId.toJson());
  }

  @override
  Future<List<MaintenanceLogModel>> getMaintenanceLogs() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return [];

    var box = Hive.isBoxOpen('maintenance_logs')
        ? Hive.box<MaintenanceLogModel>('maintenance_logs')
        : await Hive.openBox<MaintenanceLogModel>('maintenance_logs');

    List<MaintenanceLogModel> logs =
        box.values.where((log) => log.userId == userId).toList();

    if (logs.isEmpty) {
      try {
        final snapshot = await _firestore
            .collection('maintenance_logs')
            .where('userId', isEqualTo: userId)
            .orderBy('date', descending: true)
            .get();

        logs = snapshot.docs
            .map((doc) => MaintenanceLogModel.fromJson(doc.data()))
            .toList();

        for (var log in logs) {
          await box.put(log.id, log);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching maintenance logs from Firestore: $e");
        }
      }
    }

    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  @override
  Stream<List<FuelLogModel>> getFuelLogsStream(String vehicleId) {
    final controller = StreamController<List<FuelLogModel>>();
    
    _initFuelStream(vehicleId, controller);
    
    return controller.stream;
  }

  Future<void> _initFuelStream(String vehicleId, StreamController<List<FuelLogModel>> controller) async {
    final box = Hive.isBoxOpen('fuel_logs')
        ? Hive.box<FuelLogModel>('fuel_logs')
        : await Hive.openBox<FuelLogModel>('fuel_logs');

    List<FuelLogModel> getLocal() {
      final logs = box.values.where((log) => log.vehicleId == vehicleId).toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    }

    // Yield initial local data
    if (!controller.isClosed) controller.add(getLocal());

    // Watch local changes
    final watchSub = box.watch().listen((_) {
      if (!controller.isClosed) controller.add(getLocal());
    });

    // Listen to Firestore updates
    final remoteSub = _firestore
        .collection('fuel_logs')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final remoteLogs = snapshot.docs.map((doc) => FuelLogModel.fromJson(doc.data())).toList();
      
      // Update local cache without triggering infinite loops if possible
      // (box.put will trigger box.watch, which is what we want)
      for (var log in remoteLogs) {
        if (box.get(log.id) == null || box.get(log.id)!.timestamp != log.timestamp) {
           await box.put(log.id, log);
        }
      }
    }, onError: (e) {
      debugPrint('LOG_REPO: Firestore Fuel Stream Error: $e');
    });

    controller.onCancel = () {
      watchSub.cancel();
      remoteSub.cancel();
    };
  }

  @override
  Stream<List<MaintenanceLogModel>> getMaintenanceLogsStream(String vehicleId) {
    final controller = StreamController<List<MaintenanceLogModel>>();
    
    _initMaintenanceStream(vehicleId, controller);
    
    return controller.stream;
  }

  Future<void> _initMaintenanceStream(String vehicleId, StreamController<List<MaintenanceLogModel>> controller) async {
    final box = Hive.isBoxOpen('maintenance_logs')
        ? Hive.box<MaintenanceLogModel>('maintenance_logs')
        : await Hive.openBox<MaintenanceLogModel>('maintenance_logs');

    List<MaintenanceLogModel> getLocal() {
      final logs = box.values.where((log) => log.vehicleId == vehicleId).toList();
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs;
    }

    // Yield initial local data
    if (!controller.isClosed) controller.add(getLocal());

    // Watch local changes
    final watchSub = box.watch().listen((_) {
      if (!controller.isClosed) controller.add(getLocal());
    });

    // Listen to Firestore updates
    final remoteSub = _firestore
        .collection('maintenance_logs')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final remoteLogs = snapshot.docs.map((doc) => MaintenanceLogModel.fromJson(doc.data())).toList();
      
      for (var log in remoteLogs) {
        if (box.get(log.id) == null || box.get(log.id)!.date != log.date) {
           await box.put(log.id, log);
        }
      }
    }, onError: (e) {
      debugPrint('LOG_REPO: Firestore Maintenance Stream Error: $e');
    });

    controller.onCancel = () {
      watchSub.cancel();
      remoteSub.cancel();
    };
  }
  @override
  Future<void> deleteFuelLog(String id) async {
    if (Hive.isBoxOpen('fuel_logs')) {
      final box = Hive.box<FuelLogModel>('fuel_logs');
      await box.delete(id);
    }
    await _firestore.collection('fuel_logs').doc(id).delete();
  }

  @override
  Future<void> deleteMaintenanceLog(String id) async {
    if (Hive.isBoxOpen('maintenance_logs')) {
      final box = Hive.box<MaintenanceLogModel>('maintenance_logs');
      await box.delete(id);
    }
    await _firestore.collection('maintenance_logs').doc(id).delete();
  }

  @override
  Future<void> updateFuelLog(FuelLogModel log) async {
    if (Hive.isBoxOpen('fuel_logs')) {
      final box = Hive.box<FuelLogModel>('fuel_logs');
      await box.put(log.id, log);
    }
    await _firestore.collection('fuel_logs').doc(log.id).set(log.toJson());
  }

  @override
  Future<void> updateMaintenanceLog(MaintenanceLogModel log) async {
    if (Hive.isBoxOpen('maintenance_logs')) {
      final box = Hive.box<MaintenanceLogModel>('maintenance_logs');
      await box.put(log.id, log);
    }
    await _firestore.collection('maintenance_logs').doc(log.id).set(log.toJson());
  }
}
