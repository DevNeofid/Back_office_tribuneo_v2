import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/customer_repository.dart';

class CustomerUseCase {
  final CustomerRepository customerRepository = CustomerRepository();

  CustomerUseCase();

  Future<dynamic> addCustomer(EntityModel customer) async {
    return await customerRepository.addCustomer(customer);
  }

  Future<dynamic> addEntityType(int id) async {
    return await customerRepository.addEntityType(id);
  }

  Future<dynamic> updateCustomer(EntityModel customer) async {
    return await customerRepository.updateCustomer(customer);
  }

  Future<Map<int, dynamic>> getCustomers() async {
    return await customerRepository.getCustomers();
  }

  Future<bool> deleteCustomer(int id, String type) async {
    return await customerRepository.deleteCustomer(id, type);
  }
}
