import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_voucher_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/orders_repository.dart';

class OrderUseCase {
  final OrderRepository orderRepository = OrderRepository();

  OrderUseCase();

  // Function for adding a new order
  Future<bool> addOrder(OrderSendModel order,
      {String? fileName, dynamic file, String? idempotencyKey}) async {
    return await orderRepository.addOrders(order,
        fileName: fileName, file: file, idempotencyKey: idempotencyKey);
  }

  Future<OrderUpdateResult> updateOrder(
      int idOrder, Map<String, dynamic> body) async {
    return await orderRepository.updateOrder(idOrder, body);
  }

  Future<OrderExpiryUpdateResult> updateOrderExpiryDate(
      int idOrder, String expiryDate) async {
    return await orderRepository.updateOrderExpiryDate(idOrder, expiryDate);
  }

  Future<OrderBeneficiariesModel> getBeneficiaries(int idOrder) async {
    return await orderRepository.getBeneficiaries(idOrder);
  }

  Future<BeneficiariesUpdateResult> updateBeneficiaries(
      int idOrder, List<Map<String, dynamic>> beneficiaries) async {
    return await orderRepository.updateBeneficiaries(idOrder, beneficiaries);
  }

  Future<String?> resendGiftMail(int idQrCode) async {
    return await orderRepository.resendGiftMail(idQrCode);
  }

  Future<PaginatedResult<OrderModel>> getOrders({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    return await orderRepository.getOrders(
        limit: limit, offset: offset, search: search);
  }

  Future<OrderModel?> getOrder(int idOrder) async {
    return await orderRepository.getOrder(idOrder);
  }

  Future<bool> deleteOrder(int id) async {
    return await orderRepository.deleteOrder(id);
  }

  Future<List<UrssafModel>> getUrssaf() async {
    return await orderRepository.getUrssaf();
  }

  Future createQRCode(int idOrder) async {
    dynamic res = await orderRepository.createQrCode(idOrder);
    return res;
  }

  Future createCsv(int idOrder) async {
    dynamic res = await orderRepository.createCsv(idOrder);
    return res;
  }

  Future<List<OrderVoucherModel>> getOrderVouchers(int orderId) async {
    return await orderRepository.getOrderVouchers(orderId);
  }

  Future<void> disableVoucher(int idQrCode) async {
    return await orderRepository.disableVoucher(idQrCode);
  }

  Future<VoucherExpiryUpdateResult> updateVoucherExpiryDate(
      int idQrCode, String expiryDate) async {
    return await orderRepository.updateVoucherExpiryDate(idQrCode, expiryDate);
  }

  Future<List<PaymentModel>> getPayments(int orderId) async {
    return await orderRepository.getPayments(orderId);
  }

  Future<PaymentModel> addPayment(Map payment, {String? idempotencyKey}) async {
    return await orderRepository.addPayment(payment,
        idempotencyKey: idempotencyKey);
  }

  Future<void> deletePayment(int idPayment) async {
    return await orderRepository.deletePayment(idPayment);
  }

  Future<String> getInvoiceInfos(int orderId) async {
    return await orderRepository.getInvoiceInfos(orderId);
  }

  Future createInvoice(Map invoice) async {
    return await orderRepository.createInvoice(invoice);
  }

  Future createDeliveryNote(int orderId) async {
    return await orderRepository.createDeliveryNote(orderId);
  }

  Future createSummary(int orderId) async {
    return await orderRepository.createSummary(orderId);
  }
}
