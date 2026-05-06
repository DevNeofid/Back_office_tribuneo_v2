import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/transfer_order_repository.dart';

class TransferOrderUseCase {
  final TransferOrderRepository transferOrderRepository =
      TransferOrderRepository();

  Future<PaginatedResult<TransferOrderModel>> getOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    return await transferOrderRepository.getOrders(
        limit: limit, offset: offset);
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
