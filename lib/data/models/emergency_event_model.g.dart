// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmergencyEventModelAdapter extends TypeAdapter<EmergencyEventModel> {
  @override
  final int typeId = 1;

  @override
  EmergencyEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyEventModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      triggerType: fields[2] as String,
      contactsNotifiedCount: fields[3] as int,
      locationSummary: fields[4] as String,
      resolutionStatus: fields[5] as String,
      durationSeconds: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyEventModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.triggerType)
      ..writeByte(3)
      ..write(obj.contactsNotifiedCount)
      ..writeByte(4)
      ..write(obj.locationSummary)
      ..writeByte(5)
      ..write(obj.resolutionStatus)
      ..writeByte(6)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyEventModelAdapter &&
          other.typeId == typeId;
}
