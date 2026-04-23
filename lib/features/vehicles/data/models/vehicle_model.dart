import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 3)
@JsonSerializable(explicitToJson: true)
class VehicleModel extends Equatable {
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

  @HiveField(5)
  final String userId;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  @JsonKey(defaultValue: false)
  final bool isSold;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.userId,
    this.imagePath,
    this.isSold = false,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);

  @override
  List<Object?> get props => [id, name, make, model, year, userId, imagePath, isSold];
}
