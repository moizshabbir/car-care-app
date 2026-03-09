import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:json_annotation/json_annotation.dart';

import 'location_model.dart';

part 'fuel_log_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable(explicitToJson: true)
class FuelLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int odometer;

  @HiveField(2)
  final double liters;

  @HiveField(3)
  final double cost;

  @HiveField(4)
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime timestamp;

  @HiveField(5)
  final LocationModel location;

  @HiveField(6)
  final String? vehicleId;

  @HiveField(7)
  final String? stationName;

  @HiveField(8)
  final String? odometerPhotoPath;

  FuelLogModel({
    required this.id,
    required this.odometer,
    required this.liters,
    required this.cost,
    required this.timestamp,
    required this.location,
    this.vehicleId,
    this.stationName,
    this.odometerPhotoPath,
  });

  factory FuelLogModel.fromJson(Map<String, dynamic> json) =>
      _$FuelLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$FuelLogModelToJson(this);

  static DateTime _fromJson(Timestamp timestamp) => timestamp.toDate();

  static Timestamp _toJson(DateTime date) => Timestamp.fromDate(date);
}
