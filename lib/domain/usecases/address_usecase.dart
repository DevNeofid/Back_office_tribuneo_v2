import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/address_repository.dart';

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
