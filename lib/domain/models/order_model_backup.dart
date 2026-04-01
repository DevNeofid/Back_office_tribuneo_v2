// import 'package:hive/hive.dart';

// part 'adapters/order_model.g.dart';

// @HiveType(typeId: 2)
// class OrderModel extends HiveObject {
//   @HiveField(0)
//   int? id;
//   @HiveField(1)
//   String? orderNumber;
//   @HiveField(2)
//   DateTime? orderDate;
//   @HiveField(3)
//   DateTime? expiryDate;
//   @HiveField(4)
//   int? numberOfFunds;
//   @HiveField(5)
//   double? valueByFund;
//   @HiveField(6)
//   double? totalValue;
//   @HiveField(7)
//   String? giftFrom;
//   @HiveField(8)
//   String? giftReason;

//   OrderModel(
//     this.id,
//     this.orderNumber,
//     this.orderDate,
//     this.expiryDate,
//     this.numberOfFunds,
//     this.valueByFund,
//     this.totalValue,
//     this.giftFrom,
//     this.giftReason,
//   );

//   OrderModel.fromJson(Map<String, dynamic> json) {
//     // print("### DEBUG ### -> id ${json['id']}");
//     id = json['id'];
//     // print("### DEBUG ### -> orderNumber ${json['orderNumber']}");
//     orderNumber = json['orderNumber'];
//     // print("### DEBUG ### -> orderDate ${json['orderDate']}");
//     orderDate = json['orderDate'] != null
//         ? DateTime.parse(json['orderDate']['date'].toString())
//         : null;
//     // print("### DEBUG ### -> expiryDate ${json['expiryDate']}");
//     expiryDate = json['expiryDate'] != null
//         ? DateTime.parse(json['expiryDate']['date'].toString())
//         : null;
//     // print("### DEBUG ### -> numberOfFunds ${json['numberOfFunds']}");
//     numberOfFunds = json['numberOfFunds'];
//     // print("### DEBUG ### -> valueByFund ${json['valueByFund']}");
//     valueByFund = json['valueByFund'];
//     // print("### DEBUG ### -> totalValue ${json['totalValue']}");
//     totalValue = json['totalValue'];
//     // print("### DEBUG ### -> giftFrom ${json['giftFrom']}");
//     giftFrom = json['giftFrom'];
//     // print("### DEBUG ### -> giftReason ${json['giftReason']}");
//     giftReason = json['giftReason'];
//   }
// }
