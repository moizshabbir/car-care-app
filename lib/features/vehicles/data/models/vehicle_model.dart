import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 2)
@JsonSerializable(explicitToJson: true)
class VehicleModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String make;

  @HiveField(3)
  final String model;

  @HiveField(4)
  final int year;

  VehicleModel({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);
}
