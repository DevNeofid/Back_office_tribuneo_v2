import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/customer_repository.dart';

class CustomerUseCase {
  final CustomerRepository customerRepository = CustomerRepository();

  CustomerUseCase();

  Future<void> addCustomer(EntityModel customer) async {
    await customerRepository.addCustomer(customer);
  }

  Future<void> addEntityType(int id) async {
    await customerRepository.addEntityType(id);
  }

  Future<void> updateCustomer(EntityModel customer) async {
    await customerRepository.updateCustomer(customer);
  }

  Future<Map<int, dynamic>> getCustomers() async {
    return await customerRepository.getCustomers();
  }

  Future<void> deleteCustomer(int id, String type) async {
    await customerRepository.deleteCustomer(id, type);
  }
}
