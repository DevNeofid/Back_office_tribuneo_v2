import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/orders_repository.dart';

class OrderUseCase {
  final OrderRepository orderRepository = OrderRepository();

  OrderUseCase();

  // Function for adding a new order
  Future<bool> addOrder(OrderSendModel order,
      {String? fileName, dynamic file}) async {
    return await orderRepository.addOrders(order,
        fileName: fileName, file: file);
  }

  Future<void> updateOrder(OrderSendModel order) async {
    return await orderRepository.updateOrder(order);
  }

  Future<PaginatedResult<OrderModel>> getOrders({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    return await orderRepository.getOrders(
        limit: limit, offset: offset, search: search);
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

  Future<List<PaymentModel>> getPayments(int orderId) async {
    return await orderRepository.getPayments(orderId);
  }

  Future addPayment(Map payment) async {
    return await orderRepository.addPayment(payment);
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
