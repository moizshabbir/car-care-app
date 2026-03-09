// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelLogModelAdapter extends TypeAdapter<FuelLogModel> {
  @override
  final typeId = 0;

  @override
  FuelLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelLogModel(
      id: fields[0] as String,
      odometer: (fields[1] as num).toInt(),
      liters: (fields[2] as num).toDouble(),
      cost: (fields[3] as num).toDouble(),
      timestamp: fields[4] as DateTime,
      location: fields[5] as LocationModel,
      vehicleId: fields[6] as String?,
      stationName: fields[7] as String?,
      odometerPhotoPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.odometer)
      ..writeByte(2)
      ..write(obj.liters)
      ..writeByte(3)
      ..write(obj.cost)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.vehicleId)
      ..writeByte(7)
      ..write(obj.stationName)
      ..writeByte(8)
      ..write(obj.odometerPhotoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelLogModel _$FuelLogModelFromJson(Map<String, dynamic> json) => FuelLogModel(
  id: json['id'] as String,
  odometer: (json['odometer'] as num).toInt(),
  liters: (json['liters'] as num).toDouble(),
  cost: (json['cost'] as num).toDouble(),
  timestamp: FuelLogModel._fromJson(json['timestamp'] as Timestamp),
  location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  vehicleId: json['vehicleId'] as String?,
  stationName: json['stationName'] as String?,
  odometerPhotoPath: json['odometerPhotoPath'] as String?,
);

Map<String, dynamic> _$FuelLogModelToJson(FuelLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'odometer': instance.odometer,
      'liters': instance.liters,
      'cost': instance.cost,
      'timestamp': FuelLogModel._toJson(instance.timestamp),
      'location': instance.location.toJson(),
      'vehicleId': instance.vehicleId,
      'stationName': instance.stationName,
      'odometerPhotoPath': instance.odometerPhotoPath,
    };
