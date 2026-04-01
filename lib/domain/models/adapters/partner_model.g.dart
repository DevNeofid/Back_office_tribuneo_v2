// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of '../partner_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class PartnerModelAdapter extends TypeAdapter<PartnerModel> {
//   @override
//   final int typeId = 3;

//   @override
//   PartnerModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return PartnerModel(
//       fields[0] as int?,
//       fields[1] as String?,
//       fields[2] as String?,
//       fields[3] as String?,
//       fields[4] as String?,
//       fields[5] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, PartnerModel obj) {
//     writer
//       ..writeByte(7)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.name)
//       ..writeByte(2)
//       ..write(obj.email)
//       ..writeByte(3)
//       ..write(obj.siret)
//       ..writeByte(4)
//       ..write(obj.phone)
//       ..writeByte(5)
//       ..write(obj.entityType);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is PartnerModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
