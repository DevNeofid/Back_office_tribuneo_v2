import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/transfer_order_repository.dart';

class TransferOrderUseCase {
  final TransferOrderRepository transferOrderRepository =
      TransferOrderRepository();

  Future<List<TransferOrderModel>> getOrders() async {
    return await transferOrderRepository.getOrders();
  }

  Future downloadFile(int id) async {
    return await transferOrderRepository.downloadFile(id);
  }

  Future<List<RefundShopModel>> awaitRefund() async {
    return await transferOrderRepository.awaitRefund();
  }

  Future refundShop() async {
    return await transferOrderRepository.refundShop();
  }

  Future editProof(String transactionNumber) async {
    return await transferOrderRepository.editProof(transactionNumber);
  }
}
