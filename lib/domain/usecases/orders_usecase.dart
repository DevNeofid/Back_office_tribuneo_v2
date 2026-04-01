import 'package:tribuneo_backoffice/domain/models/order_model.dart';
import 'package:tribuneo_backoffice/domain/models/payment_model.dart';
import 'package:tribuneo_backoffice/domain/models/urssaf_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/orders_repository.dart';

class OrderUseCase {
  final OrderRepository orderRepository = OrderRepository();

  OrderUseCase();

  // Function for adding a new order
  Future<void> addOrder(OrderSendModel order,
      {String? fileName, dynamic file}) async {
    return await orderRepository.addOrders(order,
        fileName: fileName, file: file);
  }

  Future<void> updateOrder(OrderSendModel order) async {
    return await orderRepository.updateOrder(order);
  }

  Future<List<OrderRecModel>> getOrders() async {
    return await orderRepository.getOrders();
  }

  Future<void> deleteOrder(int id) async {
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

  Future getInvoiceInfos(int orderId) async {
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
