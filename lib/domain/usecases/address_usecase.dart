import 'package:tribuneo_backoffice/domain/models/address_model.dart';
import 'package:tribuneo_backoffice/domain/repositories/address_repository.dart';

class AddressUseCase {
  final AddressRepository addressRepository = AddressRepository();

  AddressUseCase();

  Future<void> addAddress(AddressModel address) async {
    await addressRepository.addAddress(address);
  }

  Future<void> updateAddress(AddressModel address) async {
    await addressRepository.updateAddress(address);
  }
}