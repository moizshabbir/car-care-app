// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelLogModelAdapter extends TypeAdapter<FuelLogModel> {
  @override
  final int typeId = 0;

  @override
  FuelLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelLogModel(
      id: fields[0] as String,
      odometer: fields[1] as int,
      liters: fields[2] as double,
      cost: fields[3] as double,
      timestamp: fields[4] as DateTime,
      location: fields[5] as LocationModel,
    );
  }

  @override
  void write(BinaryWriter writer, FuelLogModel obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.location);
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
      location:
          LocationModel.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FuelLogModelToJson(FuelLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'odometer': instance.odometer,
      'liters': instance.liters,
      'cost': instance.cost,
      'timestamp': FuelLogModel._toJson(instance.timestamp),
      'location': instance.location.toJson(),
    };
