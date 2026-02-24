// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceLogModelAdapter extends TypeAdapter<MaintenanceLogModel> {
  @override
  final int typeId = 1;

  @override
  MaintenanceLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaintenanceLogModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      category: fields[2] as String,
      cost: fields[3] as double,
      note: fields[4] as String,
      photoPath: fields[5] as String?,
      odometer: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.cost)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.photoPath)
      ..writeByte(6)
      ..write(obj.odometer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceLogModel _$MaintenanceLogModelFromJson(Map<String, dynamic> json) =>
    MaintenanceLogModel(
      id: json['id'] as String,
      date: MaintenanceLogModel._fromJson(json['date'] as Timestamp),
      category: json['category'] as String,
      cost: (json['cost'] as num).toDouble(),
      note: json['note'] as String,
      photoPath: json['photoPath'] as String?,
      odometer: json['odometer'] as int?,
    );

Map<String, dynamic> _$MaintenanceLogModelToJson(
        MaintenanceLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': MaintenanceLogModel._toJson(instance.date),
      'category': instance.category,
      'cost': instance.cost,
      'note': instance.note,
      'photoPath': instance.photoPath,
      'odometer': instance.odometer,
    };
