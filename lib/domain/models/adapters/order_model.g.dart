// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'order_model_backup.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class OrderModelAdapter extends TypeAdapter<OrderModel> {
//   @override
//   final int typeId = 2;

//   @override
//   OrderModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return OrderModel(
//       fields[0] as int?,
//       fields[1] as String?,
//       fields[2] as DateTime?,
//       fields[3] as DateTime?,
//       fields[4] as int?,
//       fields[5] as double?,
//       fields[6] as double?,
//       fields[7] as String?,
//       fields[8] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, OrderModel obj) {
//     writer
//       ..writeByte(8)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.orderNumber)
//       ..writeByte(2)
//       ..write(obj.orderDate)
//       ..writeByte(3)
//       ..write(obj.expiryDate)
//       ..writeByte(4)
//       ..write(obj.numberOfFunds)
//       ..writeByte(5)
//       ..write(obj.valueByFund)
//       ..writeByte(6)
//       ..write(obj.totalValue)
//       ..writeByte(7)
//       ..write(obj.giftFrom)
//       ..writeByte(8)
//       ..write(obj.giftReason);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is OrderModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
