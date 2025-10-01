
// GENERATED MANUALLY - Hive TypeAdapters for Medication and HistoryEntry
part of 'med_model.dart';

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 0;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Medication(
      name: fields[0] as String,
      dose: fields[1] as String,
      strength: fields[2] as String,
      hour: fields[3] as int,
      minute: fields[4] as int,
      colorValue: fields[5] as int,
      frequencyHours: (fields[6] as int?) ?? 8,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.dose)
      ..writeByte(2)
      ..write(obj.strength)
      ..writeByte(3)
      ..write(obj.hour)
      ..writeByte(4)
      ..write(obj.minute)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.frequencyHours);
  }
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 1;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HistoryEntry(
      dateTime: fields[0] as DateTime,
      medName: fields[1] as String,
      taken: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateTime)
      ..writeByte(1)
      ..write(obj.medName)
      ..writeByte(2)
      ..write(obj.taken);
  }
}
