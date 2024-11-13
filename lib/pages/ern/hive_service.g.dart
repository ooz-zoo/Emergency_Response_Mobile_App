// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverConditionAdapter extends TypeAdapter<DriverCondition> {
  @override
  final int typeId = 0;

  @override
  DriverCondition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverCondition(
      condition: fields[0] as String,
      safetyScore: fields[1] as int,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DriverCondition obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.condition)
      ..writeByte(1)
      ..write(obj.safetyScore)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverConditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
